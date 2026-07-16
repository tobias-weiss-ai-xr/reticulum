defmodule RetWeb.Guardian.AuthErrorHandler do
  @moduledoc false
  import Plug.Conn

  def auth_error(conn, {_type, _reason}, _opts) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Poison.encode!(%{entries: [], meta: %{next_cursor: nil}, suggestions: []}))
  end
end
