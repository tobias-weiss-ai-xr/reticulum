defmodule RetWeb.Api.V1.HubSessionController do
  use RetWeb, :controller
  import RetWeb.ApiHelpers

  alias Ret.{HubSession, Hub, Repo}
  alias RetWeb.Api.V1.HubSessionView

  @doc """
  List all sessions for a hub.
  Optional query params: state, after, before
  """
  def index(conn, %{"hub_id" => hub_id} = params) do
    with %Hub{} = hub <- Repo.get_by(Hub, hub_sid: hub_id),
         true <- Ret.Hub.is_creator?(hub, conn.assigns[:account]) do
      filters = build_filters(params)
      sessions = HubSession.list_sessions_for_hub(hub.id, filters) |> Repo.all()
      json(conn, %{data: Phoenix.View.render_many(sessions, HubSessionView, :session)})
    else
      nil ->
        conn |> send_resp(404, %{errors: [%{code: :NOT_FOUND, detail: "Hub not found."}]} |> Poison.encode!())
      false ->
        conn |> send_resp(403, %{errors: [%{code: :FORBIDDEN, detail: "Not authorized."}]} |> Poison.encode!())
    end
  end

  @doc """
  Create a new scheduled session.
  Body: title, start_time, end_time, description?, recurrence_pattern?, recurrence_end_date?, max_participants?
  """
  def create(conn, params) do
    hub_id = params["hub_id"]
    account = conn.assigns[:account]

    with %Hub{} = hub <- Repo.get_by(Hub, hub_sid: hub_id),
         true <- Ret.Hub.is_creator?(hub, account) do
      case HubSession.create_session(Map.put(params, :creator_account_id, account.account_id)) do
        {:ok, session} ->
          json(conn, %{data: Phoenix.View.render(HubSessionView, :session, session: session)})
        {:error, changeset} ->
          conn
          |> send_resp(400, %{errors: [%{code: :INVALID, detail: changeset_errors(changeset)}]} |> Poison.encode!())
      end
    else
      nil ->
        conn |> send_resp(404, %{errors: [%{code: :NOT_FOUND, detail: "Hub not found."}]} |> Poison.encode!())
      false ->
        conn |> send_resp(403, %{errors: [%{code: :FORBIDDEN, detail: "Not authorized."}]} |> Poison.encode!())
    end
  end

  @doc """
  Get a specific session by ID.
  """
  def show(conn, %{"hub_id" => _hub_id, "id" => id}) do
    case HubSession.get_session(id) do
      nil ->
        conn |> send_resp(404, %{errors: [%{code: :NOT_FOUND, detail: "Session not found."}]} |> Poison.encode!())
      session ->
        json(conn, %{data: Phoenix.View.render(HubSessionView, :session, session: session)})
    end
  end

  @doc """
  Update a session.
  """
  def update(conn, %{"hub_id" => _hub_id, "id" => id} = params) do
    with %HubSession{} = session <- HubSession.get_session(id),
         {:ok, updated} <- HubSession.update_session(session, params) do
      json(conn, %{data: Phoenix.View.render(HubSessionView, :session, session: updated)})
    else
      nil ->
        conn |> send_resp(404, %{errors: [%{code: :NOT_FOUND, detail: "Session not found."}]} |> Poison.encode!())
      {:error, changeset} ->
        conn |> send_resp(400, %{errors: [%{code: :INVALID, detail: changeset_errors(changeset)}]} |> Poison.encode!())
    end
  end

  @doc """
  Cancel a scheduled session.
  """
  def cancel(conn, %{"hub_id" => _hub_id, "id" => id}) do
    with %HubSession{} = session <- HubSession.get_session(id),
         {:ok, updated} <- HubSession.cancel_session(session) do
      json(conn, %{data: Phoenix.View.render(HubSessionView, :session, session: updated)})
    else
      nil ->
        conn |> send_resp(404, %{errors: [%{code: :NOT_FOUND, detail: "Session not found."}]} |> Poison.encode!())
      {:error, _changeset} ->
        conn |> send_resp(400, %{errors: [%{code: :INVALID, detail: "Failed to cancel session."}]} |> Poison.encode!())
    end
  end

  @doc """
  List upcoming sessions for a hub.
  """
  def upcoming(conn, %{"hub_id" => hub_id}) do
    with %Hub{} = hub <- Repo.get_by(Hub, hub_sid: hub_id),
         true <- Ret.Hub.is_creator?(hub, conn.assigns[:account]) do
      sessions = HubSession.list_upcoming_sessions(hub.id)
      json(conn, %{data: Phoenix.View.render_many(sessions, HubSessionView, :session)})
    else
      nil ->
        conn |> send_resp(404, %{errors: [%{code: :NOT_FOUND, detail: "Hub not found."}]} |> Poison.encode!())
      false ->
        conn |> send_resp(403, %{errors: [%{code: :FORBIDDEN, detail: "Not authorized."}]} |> Poison.encode!())
    end
  end

  defp build_filters(params) do
    filters = []
    filters = if params["state"], do: [{:state, params["state"]} | filters], else: filters
    filters = if params["after"], do: [{:after_time, parse_datetime(params["after"])} | filters], else: filters
    filters = if params["before"], do: [{:before_time, parse_datetime(params["before"])} | filters], else: filters
    Enum.reverse(filters)
  end

  defp parse_datetime(datetime_str) do
    case NaiveDateTime.from_iso8601(datetime_str) do
      {:ok, dt} -> dt
      _ -> NaiveDateTime.utc_now()
    end
  end

  defp changeset_errors(changeset) do
    changeset
    |> Ecto.Changeset.traverse_errors(fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
    |> Enum.map(fn {k, v} -> "#{k}: #{Enum.join(v, ", ")}" end)
    |> Enum.join("; ")
  end
end
