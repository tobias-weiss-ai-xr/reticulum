defmodule RetWeb.RoomAccessControllerTest do
  use RetWeb.ConnCase
  import Ret.TestHelpers
  alias Ret.{Hub, Repo}

  setup [:create_account]

  describe "POST /api/v1/rooms/token" do
    @tag :authenticated
    test "generates a room access token with default role", %{conn: conn} do
      %{"access_token" => token, "room_id" => room_id, "role" => role} =
        conn
        |> post(api_v1_room_access_path(conn, :create), %{room_id: "abc123"})
        |> json_response(201)

      assert is_binary(token)
      assert token != ""
      assert room_id == "abc123"
      assert role == "student"
    end

    @tag :authenticated
    test "generates a room access token with teacher role", %{conn: conn} do
      %{"access_token" => token, "room_id" => room_id, "role" => role} =
        conn
        |> post(api_v1_room_access_path(conn, :create), %{room_id: "abc123", role: "teacher"})
        |> json_response(201)

      assert is_binary(token)
      assert room_id == "abc123"
      assert role == "teacher"
    end

    @tag :authenticated
    test "generates a token with student role explicitly", %{conn: conn} do
      %{"access_token" => token, "room_id" => room_id, "role" => role} =
        conn
        |> post(api_v1_room_access_path(conn, :create), %{room_id: "abc123", role: "student"})
        |> json_response(201)

      assert is_binary(token)
      assert room_id == "abc123"
      assert role == "student"
    end

    @tag :authenticated
    test "rejects invalid role", %{conn: conn} do
      conn
      |> post(api_v1_room_access_path(conn, :create), %{room_id: "abc123", role: "admin"})
      |> json_response(422)
    end

    @tag :authenticated
    test "returns 422 when room_id is missing", %{conn: conn} do
      conn
      |> post(api_v1_room_access_path(conn, :create), %{})
      |> json_response(422)
    end

    test "returns 401 when not authenticated", %{conn: conn} do
      conn
      |> post(api_v1_room_access_path(conn, :create), %{room_id: "abc123"})
      |> response(401)
    end

    @tag :authenticated
    test "token is a valid JWT with proper claims", %{conn: conn} do
      %{"access_token" => token} =
        conn
        |> post(api_v1_room_access_path(conn, :create), %{room_id: "abc123", role: "teacher"})
        |> json_response(201)

      # Decode without verification to check claims structure
      %{claims: claims} = Ret.PermsToken.peek(token)
      assert claims["join_hub"] == true
      assert claims["room_id"] == "abc123"
      assert claims["role"] == "teacher"
      assert claims["aud"] == "ret_perms"
      assert claims["exp"] > System.system_time(:second)
    end
  end

  describe "POST /api/v1/rooms/classroom" do
    @tag :authenticated
    test "creates classroom with chemistry data", %{conn: conn} do
      resp =
        conn
        |> post(api_v1_room_access_path(conn, :create_classroom), %{
          name: "Hydrogen Classroom",
          user_data: %{chemistry: %{symbol: "H"}}
        })
        |> json_response(201)

      assert resp["room_id"] != nil
      assert resp["name"] == "Hydrogen Classroom"
      assert resp["access_token"] != nil
      assert is_binary(resp["access_token"])
      assert resp["role"] == "teacher"
      # entry_mode may be nil for newly created hubs
    end

    @tag :authenticated
    test "creates classroom without chemistry data", %{conn: conn} do
      resp =
        conn
        |> post(api_v1_room_access_path(conn, :create_classroom), %{
          name: "Plain Classroom"
        })
        |> json_response(201)

      assert resp["room_id"] != nil
      assert resp["name"] == "Plain Classroom"
      assert resp["access_token"] != nil
    end

    @tag :authenticated
    test "rejects invalid chemistry data", %{conn: conn} do
      conn
      |> post(api_v1_room_access_path(conn, :create_classroom), %{
        name: "Bad Chemistry",
        user_data: %{chemistry: %{symbol: "Zz"}}
      })
      |> response(400)
    end

    @tag :authenticated
    test "rejects request without name", %{conn: conn} do
      conn
      |> post(api_v1_room_access_path(conn, :create_classroom), %{
        user_data: %{chemistry: %{symbol: "H"}}
      })
      |> response(422)
    end

    test "returns 401 when not authenticated", %{conn: conn} do
      conn
      |> post(api_v1_room_access_path(conn, :create_classroom), %{
        name: "Unauthenticated Classroom"
      })
      |> response(401)
    end

    @tag :authenticated
    test "access token from created classroom is valid for joining", %{conn: conn} do
      resp =
        conn
        |> post(api_v1_room_access_path(conn, :create_classroom), %{
          name: "Joinable Classroom"
        })
        |> json_response(201)

      access_token = resp["access_token"]
      room_id = resp["room_id"]

      join_resp =
        conn
        |> Plug.Conn.put_req_header("x-room-access-token", access_token)
        |> post(api_v1_room_access_path(conn, :join, room_id))
        |> json_response(200)

      assert join_resp["room_id"] == room_id
      assert join_resp["role"] == "teacher"
    end
  end

  describe "POST /api/v1/rooms/:room_id/join" do
    @tag :authenticated
    test "joins a room with valid token", %{conn: conn, account: account} do
      scene = create_scene(account)
      {:ok, hub} = %Hub{} |> Hub.changeset(scene, %{name: "Test Room"}) |> Repo.insert()
      {:ok, token, _claims} = Ret.Room.Token.generate(account, hub.hub_sid, role: "student")

      conn =
        conn
        |> Plug.Conn.put_req_header("x-room-access-token", token)
        |> post(api_v1_room_access_path(conn, :join, hub.hub_sid))

      resp = json_response(conn, 200)
      assert resp["room_id"] == hub.hub_sid
      assert resp["name"] == "Test Room"
      assert resp["role"] == "student"
      assert resp["entry_mode"] != nil
      assert resp["url"] != nil
    end

    @tag :authenticated
    test "rejects room_id mismatch", %{conn: conn, account: account} do
      {:ok, token, _claims} = Ret.Room.Token.generate(account, "room_abc", role: "student")

      conn =
        conn
        |> Plug.Conn.put_req_header("x-room-access-token", token)
        |> post(api_v1_room_access_path(conn, :join, "wrong_room"))

      assert conn.status == 403
      assert conn.resp_body =~ "token_room_id_mismatch"
    end

    @tag :authenticated
    test "returns 404 for non-existent room", %{conn: conn, account: account} do
      {:ok, token, _claims} = Ret.Room.Token.generate(account, "nonexistent_room", role: "student")

      conn =
        conn
        |> Plug.Conn.put_req_header("x-room-access-token", token)
        |> post(api_v1_room_access_path(conn, :join, "nonexistent_room"))

      assert conn.status == 404
      assert conn.resp_body =~ "room_not_found"
    end

    test "returns 403 when not authenticated", %{conn: conn} do
      conn
      |> post(api_v1_room_access_path(conn, :join, "any_room"))
      |> response(403)
    end

    @tag :authenticated
    test "returns 403 without valid room access token", %{conn: conn} do
      conn
      |> post(api_v1_room_access_path(conn, :join, "any_room"))
      |> response(403)
    end

    @tag :authenticated
    test "joins with teacher role", %{conn: conn, account: account} do
      scene = create_scene(account)
      {:ok, hub} = %Hub{} |> Hub.changeset(scene, %{name: "Teacher Room"}) |> Repo.insert()
      {:ok, token, _claims} = Ret.Room.Token.generate(account, hub.hub_sid, role: "teacher")

      conn =
        conn
        |> Plug.Conn.put_req_header("x-room-access-token", token)
        |> post(api_v1_room_access_path(conn, :join, hub.hub_sid))

      resp = json_response(conn, 200)
      assert resp["role"] == "teacher"
    end
  end
end
