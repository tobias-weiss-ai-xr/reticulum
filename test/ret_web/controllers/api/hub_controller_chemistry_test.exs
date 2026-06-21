defmodule RetWeb.HubControllerChemistryTest do
  use RetWeb.ConnCase
  import Ret.TestHelpers

  alias Ret.{Hub, Repo}

  setup [:create_account, :create_owned_file, :create_scene]

  describe "POST /api/v1/hubs — chemistry validation" do
    test "accepts valid chemistry data in user_data", %{conn: conn} do
      %{"status" => "ok", "hub_id" => hub_id} =
        conn
        |> create_hub_with_attrs(%{
          name: "Hydrogen Room",
          user_data: %{chemistry: %{symbol: "H"}}
        })
        |> json_response(200)

      hub = Hub |> Repo.get_by(hub_sid: hub_id)
      assert hub.user_data["chemistry"]["symbol"] == "H"
    end

    test "rejects invalid element symbol", %{conn: conn} do
      conn
      |> create_hub_with_attrs(%{
        name: "Fake Element Room",
        user_data: %{chemistry: %{symbol: "Zz"}}
      })
      |> response(400)
    end

    test "rejects chemistry data without symbol key", %{conn: conn} do
      conn
      |> create_hub_with_attrs(%{
        name: "Bad Chemistry Room",
        user_data: %{chemistry: %{other: "no_symbol"}}
      })
      |> response(400)
    end

    test "rejects chemistry data with non-string symbol", %{conn: conn} do
      conn
      |> create_hub_with_attrs(%{
        name: "Bad Chemistry Room",
        user_data: %{chemistry: %{symbol: 123}}
      })
      |> response(400)
    end

    test "allows chemistry-agnostic rooms", %{conn: conn} do
      %{"status" => "ok"} =
        conn
        |> create_hub_with_attrs(%{name: "Plain Room", user_data: %{color: "blue"}})
        |> json_response(200)
    end

    test "allows rooms without user_data", %{conn: conn} do
      %{"status" => "ok"} =
        conn
        |> create_hub("Normal Room")
        |> json_response(200)
    end
  end

  describe "GET /api/v1/hubs/element/:element_symbol" do
    test "returns rooms for valid element symbol and includes pse_url", %{conn: conn} do
      %{"hub_id" => hub_id} =
        conn
        |> create_hub_with_attrs(%{
          name: "Hydrogen Room",
          user_data: %{chemistry: %{symbol: "H"}}
        })
        |> json_response(200)

      %{"hubs" => hubs} =
        build_conn()
        |> get(api_v1_hub_path(build_conn(), :index_by_element, "H"))
        |> json_response(200)

      assert length(hubs) >= 1
      returned = Enum.find(hubs, fn h -> h["hub_id"] == hub_id end)
      assert returned["name"] == "Hydrogen Room"
      assert returned["pse_url"] == "https://pse.chemie-lernen.org?element=H"
    end

    test "includes pse_url for multi-char element symbols", %{conn: conn} do
      conn
      |> create_hub_with_attrs(%{
        name: "Helium Room",
        user_data: %{chemistry: %{symbol: "He"}}
      })
      |> json_response(200)

      %{"hubs" => hubs} =
        build_conn()
        |> get(api_v1_hub_path(build_conn(), :index_by_element, "He"))
        |> json_response(200)

      assert length(hubs) >= 1
      assert hd(hubs)["pse_url"] == "https://pse.chemie-lernen.org?element=He"
    end

    test "returns empty list for unmatched element", %{conn: conn} do
      conn
      |> get(api_v1_hub_path(conn, :index_by_element, "Zz"))
      |> json_response(200)
      |> assert_hubs_empty()
    end

    test "returns 200 and empty for unknown element", %{conn: conn} do
      conn
      |> get(api_v1_hub_path(conn, :index_by_element, "NonExistent"))
      |> json_response(200)
      |> assert_hubs_empty()
    end

    test "returns rooms only for the requested element", %{conn: conn, scene: scene} do
      {:ok, _h_hub} =
        %Hub{}
        |> Hub.changeset(scene, %{
          name: "Hydrogen Only",
          user_data: %{chemistry: %{symbol: "H"}}
        })
        |> Repo.insert()

      {:ok, _he_hub} =
        %Hub{}
        |> Hub.changeset(scene, %{
          name: "Helium Only",
          user_data: %{chemistry: %{symbol: "He"}}
        })
        |> Repo.insert()

      %{"hubs" => hubs} =
        conn
        |> get(api_v1_hub_path(conn, :index_by_element, "H"))
        |> json_response(200)

      assert length(hubs) == 1
      assert hd(hubs)["name"] == "Hydrogen Only"
    end
  end

  defp assert_hubs_empty(%{"hubs" => hubs}) do
    assert hubs == []
  end

  defp create_hub(conn, name) do
    create_hub_with_attrs(conn, %{name: name})
  end

  defp create_hub_with_attrs(conn, attrs) do
    req = conn |> api_v1_hub_path(:create, %{"hub" => attrs})
    conn |> post(req)
  end
end
