defmodule RetWeb.Plugs.RoomAccessTest do
  use RetWeb.ConnCase
  import Ret.TestHelpers

  alias Ret.PermsToken

  setup [:create_account]

  describe "extract_bearer_token" do
    test "accepts valid token", %{conn: conn, account: account} do
      {:ok, token, _claims} = Ret.Room.Token.generate(account, "room_abc", role: "teacher")

      conn =
        conn
        |> Plug.Conn.put_req_header("x-room-access-token", token)
        |> RetWeb.Plugs.RoomAccess.call([])

      assert conn.assigns.room_access_claims.room_id == "room_abc"
      assert conn.assigns.room_access_claims.user_id == "#{account.account_id}_global"
      assert conn.assigns.room_access_claims.role == "teacher"
      refute conn.halted
    end

    test "rejects missing header", %{conn: conn} do
      conn = RetWeb.Plugs.RoomAccess.call(conn, [])

      assert conn.status == 403
      assert conn.halted
      assert conn.resp_body =~ "missing_room_access_token"
    end

    test "rejects empty token", %{conn: conn} do
      conn =
        conn
        |> Plug.Conn.put_req_header("x-room-access-token", "")
        |> RetWeb.Plugs.RoomAccess.call([])

      assert conn.status == 403
      assert conn.halted
      assert conn.resp_body =~ "missing_room_access_token"
    end
  end

  describe "validate_room_claims" do
    test "accepts token with room_id claim", %{conn: conn, account: account} do
      {:ok, token, _claims} = Ret.Room.Token.generate(account, "room_xyz")

      conn =
        conn
        |> Plug.Conn.put_req_header("x-room-access-token", token)
        |> RetWeb.Plugs.RoomAccess.call([])

      assert conn.assigns.room_access_claims.room_id == "room_xyz"
      refute conn.halted
    end

    test "rejects token without join_hub claim", %{conn: conn} do
      {:ok, bad_token, _claims} =
        PermsToken.encode_and_sign(nil, %{room_id: "abc"}, ttl: {1, :minutes}, allowed_drift: 60 * 1000)

      conn =
        conn
        |> Plug.Conn.put_req_header("x-room-access-token", bad_token)
        |> RetWeb.Plugs.RoomAccess.call([])

      assert conn.status == 403
      assert conn.halted
      assert conn.resp_body =~ "invalid_room_access_token"
    end

    test "rejects expired token", %{conn: conn, account: account} do
      {:ok, token, _claims} =
        Ret.Room.Token.generate(account, "room_expired", ttl_seconds: -1)

      conn =
        conn
        |> Plug.Conn.put_req_header("x-room-access-token", token)
        |> RetWeb.Plugs.RoomAccess.call([])

      assert conn.status == 403
      assert conn.halted
      assert conn.resp_body =~ "expired"
    end

    test "rejects token without any claims", %{conn: conn} do
      {:ok, bad_token, _claims} =
        PermsToken.encode_and_sign(nil, %{}, ttl: {1, :minutes}, allowed_drift: 60 * 1000)

      conn =
        conn
        |> Plug.Conn.put_req_header("x-room-access-token", bad_token)
        |> RetWeb.Plugs.RoomAccess.call([])

      assert conn.status == 403
      assert conn.halted
      assert conn.resp_body =~ "invalid_room_access_token"
    end
  end

  describe "store_claims" do
    test "stores full claims map in assigns", %{conn: conn, account: account} do
      {:ok, token, _claims} = Ret.Room.Token.generate(account, "room_store", role: "teacher")

      conn =
        conn
        |> Plug.Conn.put_req_header("x-room-access-token", token)
        |> RetWeb.Plugs.RoomAccess.call([])

      claims = conn.assigns.room_access_claims
      assert claims.room_id == "room_store"
      assert claims.user_id == "#{account.account_id}_global"
      assert claims.role == "teacher"
      assert is_integer(claims.exp)
      assert claims.exp > 0
    end

    test "defaults role to student", %{conn: conn, account: account} do
      {:ok, token, _claims} = Ret.Room.Token.generate(account, "room_default_role")

      conn =
        conn
        |> Plug.Conn.put_req_header("x-room-access-token", token)
        |> RetWeb.Plugs.RoomAccess.call([])

      assert conn.assigns.room_access_claims.role == "student"
    end
  end

  describe "Ret.Room.Token" do
    test "generate returns token with room_id and role in claims" do
      account = create_account("token_test")
      {:ok, token, claims} = Ret.Room.Token.generate(account, "room_gen", role: "student")

      assert is_binary(token)
      assert claims["room_id"] == "room_gen"
      assert claims["role"] == "student"
      assert claims["join_hub"] == true
      assert claims["sub"] == "#{account.account_id}_global"
      assert claims["exp"] > 0
      assert claims["iat"] > 0
    end

    test "accepts teacher role" do
      account = create_account("teacher_test")
      {:ok, _token, claims} = Ret.Room.Token.generate(account, "room_t", role: "teacher")

      assert claims["role"] == "teacher"
    end

    test "round-trips through verify" do
      account = create_account("rt_test")
      {:ok, token, _claims} = Ret.Room.Token.generate(account, "room_rt", role: "teacher")
      {:ok, verified_claims} = Ret.Room.Token.verify(token)

      assert verified_claims["room_id"] == "room_rt"
      assert verified_claims["role"] == "teacher"
      assert verified_claims["join_hub"] == true
      assert verified_claims["sub"] == "#{account.account_id}_global"
    end
  end
end
