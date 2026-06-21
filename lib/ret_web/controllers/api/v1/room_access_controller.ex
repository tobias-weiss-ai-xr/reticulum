defmodule RetWeb.Api.V1.RoomAccessController do
  use RetWeb, :controller

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
