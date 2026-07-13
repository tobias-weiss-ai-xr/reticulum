defmodule RetWeb.Plugs.RoomAccess do
  @moduledoc """
  Room Access Control Middleware.

  Validates JWT room access tokens before allowing users to enter chemistry VR rooms.
  Extracts the Bearer token from the Authorization header, verifies it via
  `Ret.PermsToken.decode_and_verify/1` (RS512-signed perms tokens), then checks
  for room-specific claims:
  - `join_hub`: must be `true` (required)
  - `room_id`: the room being accessed (required)
  - `sub`: the user_id
  - `role`: "teacher" or "student" (defaults to "student")
  - `exp`: token expiry (checked against current time)

  On success, stores validated claims in `conn.assigns.room_access_claims`.
  On failure, returns 403 with a JSON error body.
  """
  import Plug.Conn
  alias Ret.PermsToken

  def init([]), do: []

  def call(conn, []) do
    with {:ok, token} <- extract_bearer_token(conn),
         {:ok, claims} <- PermsToken.decode_and_verify(token),
         :ok <- validate_room_claims(claims) do
      assign(conn, :room_access_claims, %{
        room_id: claims["room_id"],
        user_id: claims["sub"],
        role: Map.get(claims, "role", "student"),
        exp: claims["exp"]
      })
    else
      {:error, :missing_token} ->
        conn
        |> send_resp(403, Jason.encode!(%{error: "missing_room_access_token"}))
        |> halt()

      {:error, :expired_token} ->
        conn
        |> send_resp(403, Jason.encode!(%{error: "room_access_token_expired"}))
        |> halt()

      {:error, :token_expired} ->
        conn
        |> send_resp(403, Jason.encode!(%{error: "room_access_token_expired"}))
        |> halt()

      {:error, :missing_room_id} ->
        conn
        |> send_resp(403, Jason.encode!(%{error: "token_missing_room_id"}))
        |> halt()

      {:error, _reason} ->
        conn
        |> send_resp(403, Jason.encode!(%{error: "invalid_room_access_token"}))
        |> halt()
    end
  end

  defp extract_bearer_token(conn) do
    case get_req_header(conn, "x-room-access-token") do
      [token] when token != "" -> {:ok, token}
      _ -> {:error, :missing_token}
    end
  end

  defp validate_room_claims(claims) do
    cond do
      !Map.get(claims, "join_hub", false) ->
        {:error, :invalid_token}

      is_nil(claims["room_id"]) ->
        {:error, :missing_room_id}

      is_expired?(claims) ->
        {:error, :expired_token}

      true ->
        :ok
    end
  end

  defp is_expired?(claims) do
    case Map.get(claims, "exp") do
      nil -> false
      exp -> DateTime.to_unix(DateTime.utc_now()) > exp
    end
  end
end
