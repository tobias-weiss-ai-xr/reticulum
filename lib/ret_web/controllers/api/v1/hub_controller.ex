defmodule RetWeb.Api.V1.HubController do
  use RetWeb, :controller

  alias Ret.{Hub, Scene, Repo}

  import Canada, only: [can?: 2]

  # Limit to 1 TPS
  plug RetWeb.Plugs.RateLimit

  def create(conn, %{"hub" => _hub_params} = params) do
    hub_params = params["hub"]
    chemistry = get_in(hub_params, ["user_data", "chemistry"])

    case Ret.Chemistry.validate_chemistry_data(chemistry) do
      :ok ->
        Hub.create_new_room(hub_params, false)
        |> exec_create(conn)

      {:error, reason} ->
        conn |> send_resp(400, reason)
    end
  end

  defp exec_create(hub_changeset, conn) do
    account = Guardian.Plug.current_resource(conn)

    if account |> can?(create_hub(nil)) do
      {result, hub} =
        hub_changeset
        |> Hub.add_account_to_changeset(account)
        |> Repo.insert()

      case result do
        :ok -> render(conn, "create.json", hub: hub)
        :error -> conn |> send_resp(422, "invalid hub")
      end
    else
      conn |> send_resp(401, "unauthorized")
    end
  end

  def update(conn, %{"id" => hub_sid, "hub" => hub_params}) do
    account = Guardian.Plug.current_resource(conn)

    case Hub
         |> Repo.get_by(hub_sid: hub_sid)
         |> Repo.preload([:created_by_account, :hub_bindings, :hub_role_memberships]) do
      %Hub{} = hub ->
        if account |> can?(update_hub(hub)) do
          update_with_hub(conn, account, hub, hub_params)
        else
          conn |> send_resp(401, "You cannot update this hub")
        end

      _ ->
        conn |> send_resp(404, "not found")
    end
  end

  defp update_with_hub(conn, account, hub, hub_params) do
    chemistry = get_in(hub_params, ["user_data", "chemistry"])

    case Ret.Chemistry.validate_chemistry_data(chemistry) do
      :ok ->
        if is_nil(hub_params["scene_id"]) do
          update_with_hub_and_scene(conn, account, hub, nil, hub_params)
        else
          case Scene.scene_or_scene_listing_by_sid(hub_params["scene_id"]) do
            nil -> conn |> send_resp(422, "scene not found")
            scene -> update_with_hub_and_scene(conn, account, hub, scene, hub_params)
          end
        end

      {:error, reason} ->
        conn |> send_resp(400, reason)
    end
  end

  defp update_with_hub_and_scene(conn, account, hub, scene, hub_params) do
    changeset =
      hub
      |> Hub.add_attrs_to_changeset(hub_params)
      |> maybe_add_new_scene(scene)
      |> Hub.maybe_add_member_permissions(hub, hub_params)
      |> Hub.maybe_add_promotion(account, hub, hub_params)

    hub = changeset |> Repo.update!() |> Repo.preload(Hub.hub_preloads())

    conn |> render("show.json", %{hub: hub, embeddable: account |> can?(embed_hub(hub))})
  end

  defp maybe_add_new_scene(changeset, nil), do: changeset

  defp maybe_add_new_scene(changeset, scene),
    do: changeset |> Hub.add_new_scene_to_changeset(scene)

  def delete(conn, %{"id" => hub_sid}) do
    hub = Repo.get_by(Hub, hub_sid: hub_sid)
    account = Guardian.Plug.current_resource(conn)

    cond do
      is_nil(hub) ->
        conn |> send_resp(404, "Hub not found")

      conn.halted ->
        conn

      account && Hub.is_creator?(hub, account.account_id) ->
        hub
        |> Hub.changeset_for_entry_mode(:deny)
        |> Repo.update!()

        conn |> send_resp(200, "OK")

      true ->
        conn |> send_resp(403, "Forbidden")
    end
  end

  def index_by_element(conn, %{"element_symbol" => element_symbol}) do
    page = conn.params |> Map.get("page", "1") |> String.to_integer()
    page_size = conn.params |> Map.get("page_size", "100") |> String.to_integer()

    page_result = Hub.get_element_rooms(element_symbol, %{page: page, page_size: page_size})

    render(conn, "index.json", hubs: page_result.entries, page_result: page_result)
  end

  def analytics(conn, %{"id" => hub_sid}) do
    hub = Repo.get_by(Hub, hub_sid: hub_sid)
    account = Guardian.Plug.current_resource(conn)

    cond do
      is_nil(hub) ->
        conn |> send_resp(404, "Hub not found")

      account && Hub.is_creator?(hub, account.account_id) ->
        current_members = Hub.member_count_for(hub_sid)
        current_lobby = Hub.lobby_count_for(hub_sid)
        total_present = current_members + current_lobby

        end_time = DateTime.utc_now() |> NaiveDateTime.from_datetime()
        start_time = DateTime.add(DateTime.utc_now(), -24, :hour) |> NaiveDateTime.from_datetime()
        max_ccu_24h = Ret.NodeStat.max_ccu_for_time_range(start_time, end_time)

        room_stats = %{
          current_occupants: total_present,
          members_in_room: current_members,
          members_in_lobby: current_lobby,
          max_occupants: hub.max_occupant_count,
          room_size: hub.room_size,
          max_ccu_24h: max_ccu_24h,
          last_active_at: hub.last_active_at,
          created_at: hub.inserted_at
        }

        conn |> json(%{data: room_stats})

      true ->
        conn |> send_resp(403, "Forbidden")
    end
  end

  def bulk_archive(conn, %{"hub_ids" => hub_ids}) when is_list(hub_ids) do
    account = Guardian.Plug.current_resource(conn)

    if is_nil(account) do
      conn |> send_resp(403, "Forbidden")
    else
      hubs = Repo.all(from h in Hub, where: h.hub_sid in ^hub_ids)

      {archived, forbidden} =
        Enum.reduce(hubs, {[], []}, fn hub, {archived, forbidden} ->
          if Hub.is_creator?(hub, account.account_id) do
            {:ok, _} =
              hub
              |> Hub.changeset_for_entry_mode(:deny)
              |> Repo.update()

            {[hub.hub_sid | archived], forbidden}
          else
            {archived, [hub.hub_sid | forbidden]}
          end
        end)

      conn
      |> put_status(200)
      |> json(%{
        archived: archived,
        forbidden: forbidden,
        total_requested: length(hub_ids),
        total_archived: length(archived)
      })
    end
  end

  def bulk_archive(conn, _params) do
    conn |> send_resp(400, "Invalid request: hub_ids must be an array")
  end

  def copy(conn, %{"id" => source_hub_sid} = params) do
    account = Guardian.Plug.current_resource(conn)

    if is_nil(account) do
      conn |> send_resp(403, "Forbidden")
    else
      source_hub = Repo.get_by(Hub, hub_sid: source_hub_sid)

      cond do
        is_nil(source_hub) ->
          conn |> send_resp(404, "Source room not found")

        not Hub.is_creator?(source_hub, account.account_id) ->
          conn |> send_resp(403, "Forbidden: not the room creator")

        true ->
          new_name = params["name"] || "#{source_hub.name} (Copy)"
          new_description = params["description"] || source_hub.description
          new_max_occupants = params["max_occupant_count"] || source_hub.max_occupant_count

          new_hub =
            %Hub{
              name: new_name,
              description: new_description,
              hub_sid: Ret.Utils.generate_hub_sid(),
              host: source_hub.host,
              embed_token: Ret.Utils.generate_hub_token(),
              member_permissions: source_hub.member_permissions,
              max_occupant_count: new_max_occupants,
              spawned_object_types: source_hub.spawned_object_types,
              room_size: source_hub.room_size,
              entry_mode: source_hub.entry_mode,
              created_by_account_id: account.account_id,
              scene_id: source_hub.scene_id,
              scene_listing_id: source_hub.scene_listing_id,
              default_environment_gltf_bundle_url: source_hub.default_environment_gltf_bundle_url,
              user_data: source_hub.user_data,
              allow_promotion: source_hub.allow_promotion
            }

          case Repo.insert(new_hub) do
            {:ok, copied_hub} ->
              conn
              |> put_status(201)
              |> json(%{
                data: %{
                  hub_sid: copied_hub.hub_sid,
                  name: copied_hub.name,
                  description: copied_hub.description,
                  created_at: copied_hub.inserted_at
                }
              })

            {:error, _changeset} ->
              conn |> send_resp(500, "Failed to create copy")
          end
      end
    end
  end

  # Catch-all for unmatched API v1 endpoints. Returns empty cursor-paginated response
  # matching the format the Hubs React usePaginatedAPI expects:
  # { entries: [], meta: { next_cursor: null }, suggestions: [] }
  def index_list(conn, _params) do
    conn
    |> put_view(RetWeb.Api.V1.HubView)
    |> render("empty.json", %{})
  end
end
