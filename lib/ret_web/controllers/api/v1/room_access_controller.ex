defmodule RetWeb.Api.V1.RoomAccessController do
  use RetWeb, :controller
  alias Ret.{Hub, Repo}

  plug RetWeb.Plugs.RateLimit

  def create_classroom(conn, %{"name" => _name} = params) do
    account = Guardian.Plug.current_resource(conn)

    if is_nil(account) do
      conn |> send_resp(401, "unauthorized") |> halt()
    else
      chemistry = get_in(params, ["user_data", "chemistry"])

      case Ret.Chemistry.validate_chemistry_data(chemistry) do
        :ok ->
          room_params = Map.take(params, ["name", "description", "user_data", "scene_id", "room_size"])

          case Hub.create_new_room(room_params, true) do
            {:ok, hub} ->
              hub = hub |> Repo.preload(Hub.hub_preloads())

              {:ok, access_token, _claims} =
                Ret.Room.Token.generate(account, hub.hub_sid, role: "teacher")

              conn
              |> put_status(:created)
              |> json(%{
                room_id: hub.hub_sid,
                name: hub.name,
                slug: hub.slug,
                url: Hub.url_for(hub),
                entry_mode: hub.entry_mode,
                member_permissions: Hub.member_permissions_for_hub(hub),
                access_token: access_token,
                role: "teacher"
              })

            {:error, changeset} ->
              conn
              |> put_status(:unprocessable_entity)
              |> json(%{error: "Failed to create classroom", details: inspect(changeset.errors)})
              |> halt()
          end

        {:error, reason} ->
          conn |> send_resp(400, reason) |> halt()
      end
    end
  end

  def create_classroom(conn, _params) do
    conn
    |> put_status(:unprocessable_entity)
    |> json(%{error: "name is required"})
    |> halt()
  end

  def join(conn, %{"room_id" => room_id}) do
    claims = conn.assigns.room_access_claims

    if claims.room_id != room_id do
      conn
      |> put_status(:forbidden)
      |> json(%{error: "token_room_id_mismatch"})
      |> halt()
    else
      case Hub |> Repo.get_by(hub_sid: room_id) |> Repo.preload([:scene, :scene_listing]) do
        nil ->
          conn
          |> put_status(:not_found)
          |> json(%{error: "room_not_found"})
          |> halt()

        hub ->
          perms_token =
            Ret.PermsToken.token_for_perms(%{
              join_hub: true,
              room_id: room_id,
              role: claims.role
            })

          conn
          |> put_status(:ok)
          |> json(%{
            room_id: hub.hub_sid,
            name: hub.name,
            slug: hub.slug,
            url: Hub.url_for(hub),
            entry_mode: hub.entry_mode,
            member_count: Hub.member_count_for(hub),
            lobby_count: Hub.lobby_count_for(hub),
            role: claims.role,
            perms_token: perms_token
          })
      end
    end
  end

  def create(conn, %{"room_id" => _room_id} = params) do
    role = Map.get(params, "role", "student")

    with :ok <- validate_role(role) do
      token =
        Ret.PermsToken.token_for_perms(%{
          join_hub: true,
          room_id: Map.get(params, "room_id"),
          role: role
        })

      conn
      |> put_status(:created)
      |> json(%{
        access_token: token,
        room_id: Map.get(params, "room_id"),
        role: role
      })
    else
      {:error, message} ->
        return_validation_error(conn, message)
    end
  end

  def create(conn, _params) do
    return_validation_error(conn, "room_id is required")
  end

  defp validate_role(role) when role in ["student", "teacher"], do: :ok

  defp validate_role(_), do: {:error, "role must be 'student' or 'teacher'"}

  defp return_validation_error(conn, message) do
    conn
    |> put_status(:unprocessable_entity)
    |> json(%{error: message})
    |> halt()
  end
end
