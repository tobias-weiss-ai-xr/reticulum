defmodule Ret.StorageTest do
  use Ret.DataCase
  import Ret.TestHelpers

  alias Ret.{OwnedFile, Storage}

  setup do
    on_exit(fn ->
      clear_all_stored_files()
    end)
  end

  setup _context do
    %{temp_file: generate_temp_file("test"), temp_file_2: generate_temp_file("test2")}
  end

  describe "store/fetch cycle" do
    test "store a file", %{temp_file: temp_file} do
      {:ok, uuid} = Storage.store(%Plug.Upload{path: temp_file}, "text/plain", "secret")
      result = Storage.fetch(uuid, "secret")

      assert_fetch_result(result, "text/plain", "test")
    end

    test "bad key should fail fetch", %{temp_file: temp_file} do
      {:ok, uuid} = Storage.store(%Plug.Upload{path: temp_file}, "text/plain", "secret")
      {result, message} = Storage.fetch(uuid, "secret2")

      assert result == :error
      assert message == :not_allowed
    end

    test "promote a stored file", %{temp_file: temp_file} do
      account = Ret.Repo.insert!(%Ret.Account{})

      {:ok, uuid} = Storage.store(%Plug.Upload{path: temp_file}, "text/plain", "secret")
      {:ok, owned_file} = Storage.promote(uuid, "secret", nil, account)
      result = Storage.fetch(owned_file)

      assert_fetch_result(result, "text/plain", "test")
    end

    test "should not be able to promote a file with an invalid promotion token", %{
      temp_file: temp_file
    } do
      account = Ret.Repo.insert!(%Ret.Account{})

      {:ok, uuid} =
        Storage.store(%Plug.Upload{path: temp_file}, "text/plain", "secret", "promotion_secret")

      {:error, :not_allowed} = Storage.promote(uuid, "secret", "invalid_promotion_secret", account)
    end

    test "should be able to re-promote without failure", %{temp_file: temp_file} do
      account = Ret.Repo.insert!(%Ret.Account{})

      {:ok, uuid} = Storage.store(%Plug.Upload{path: temp_file}, "text/plain", "secret")
      {:ok, _owned_file} = Storage.promote(uuid, "secret", nil, account)
      {:ok, owned_file} = Storage.promote(uuid, "secret", nil, account)

      owned_file_id = owned_file.owned_file_id

      {:ok, %OwnedFile{owned_file_id: ^owned_file_id}} =
        Storage.promote(uuid, "secret", nil, account)
    end

    test "should be able to promote multiple files", %{
      temp_file: temp_file,
      temp_file_2: temp_file_2
    } do
      account = Ret.Repo.insert!(%Ret.Account{})

      {:ok, uuid_1} = Storage.store(%Plug.Upload{path: temp_file}, "text/plain", "secret")
      {:ok, uuid_2} = Storage.store(%Plug.Upload{path: temp_file_2}, "text/plain", "secret2")

      %{t1: {:ok, owned_file_t1}, t2: {:ok, owned_file_t2}} =
        Storage.promote(%{t1: {uuid_1, "secret"}, t2: {uuid_2, "secret2"}}, account)

      r1 = Storage.fetch(owned_file_t1)
      r2 = Storage.fetch(owned_file_t2)

      assert_fetch_result(r1, "text/plain", "test")
      assert_fetch_result(r2, "text/plain", "test2")
    end
  end

  describe "uri_for/2,3" do
    defp set_storage_host(host) do
      current = Application.get_env(:ret, Ret.Storage)
      Application.put_env(:ret, Ret.Storage, Keyword.put(current, :host, host))
    end

    test "generates correct URI from configured host" do
      set_storage_host("https://hubs.example.com")
      uuid = "550e8400-e29b-41d4-a716-446655440000"
      uri = Storage.uri_for(uuid, "model/gltf-binary")
      assert %URI{scheme: "https", host: "hubs.example.com", path: "/files/550e8400-e29b-41d4-a716-446655440000.glb"} = uri
    end

    test "appends correct extension for different MIME types" do
      set_storage_host("https://hubs.example.com")

      png = Storage.uri_for("u1", "image/png")
      assert String.ends_with?(png.path, ".png")

      jpg = Storage.uri_for("u2", "image/jpeg")
      assert String.ends_with?(jpg.path, ".jpg")

      bin = Storage.uri_for("u3", "application/octet-stream")
      assert String.ends_with?(bin.path, ".bin")

      html = Storage.uri_for("u4", "text/html")
      assert String.ends_with?(html.path, ".html")
    end

    test "includes token as query param when provided" do
      set_storage_host("https://hubs.example.com")
      uri = Storage.uri_for("uuid", "text/plain", "my_secret_token")
      assert uri.query == "token=my_secret_token"
    end

    test "does not include query param when token is nil" do
      set_storage_host("https://hubs.example.com")
      uri = Storage.uri_for("uuid", "text/plain", nil)
      assert uri.query == nil
    end

    test "falls back to Endpoint.url() when host is not configured" do
      current = Application.get_env(:ret, Ret.Storage)
      Application.put_env(:ret, Ret.Storage, Keyword.drop(current, [:host]))
      uri = Storage.uri_for("test-uuid", "application/json")
      assert uri.host == "localhost"
      assert String.contains?(uri.path, "test-uuid.json")
      on_exit(fn -> Application.put_env(:ret, Ret.Storage, current) end)
    end

    test "handles unknown MIME types by omitting extension" do
      set_storage_host("https://hubs.example.com")
      uri = Storage.uri_for("uuid", "application/x-unknown-magic-type")
      assert uri.path == "/files/uuid"
    end

    test "URI has correct scheme, host, and path without port in host config" do
      set_storage_host("https://hubs.example.com")
      uuid = "b91ea51b-c21a-4f57-b3c2-6b56d93280e7"
      uri = Storage.uri_for(uuid, "model/gltf-binary")
      assert uri.scheme == "https"
      assert uri.host == "hubs.example.com"
      assert uri.port == 443
      assert uri.path == "/files/#{uuid}.glb"
    end

    test "URI preserves host and port when port 4000 is in host config" do
      set_storage_host("https://hubs.example.com:4000")
      uuid = "b91ea51b-c21a-4f57-b3c2-6b56d93280e7"
      uri = Storage.uri_for(uuid, "model/gltf-binary")
      assert uri.host == "hubs.example.com"
      assert uri.port == 4000
      assert uri.path == "/files/#{uuid}.glb"
    end
  end

  defp assert_fetch_result(result, expected_content_type, expected_content) do
    {:ok, %{"content_type" => content_type}, stream} = result

    assert content_type == expected_content_type
    assert stream |> Enum.map(& &1) |> Enum.join() == expected_content
  end
end
