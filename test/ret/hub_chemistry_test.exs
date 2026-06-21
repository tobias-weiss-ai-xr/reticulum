defmodule Ret.HubChemistryTest do
  use Ret.DataCase
  import Ret.TestHelpers

  alias Ret.{Hub, Repo}

  setup [:create_account, :create_owned_file, :create_scene]

  describe "get_element_rooms/2" do
    test "returns rooms matching the element symbol", %{scene: scene} do
      {:ok, hub} =
        %Hub{}
        |> Hub.changeset(scene, %{
          name: "Hydrogen Room",
          user_data: %{chemistry: %{symbol: "H"}}
        })
        |> Repo.insert()

      {:ok, _hub2} =
        %Hub{}
        |> Hub.changeset(scene, %{
          name: "Helium Room",
          user_data: %{chemistry: %{symbol: "He"}}
        })
        |> Repo.insert()

      assert [result] = Hub.get_element_rooms("H", nil).entries
      assert result.hub_sid == hub.hub_sid
      assert result.name == "Hydrogen Room"
      assert result.user_data["chemistry"]["symbol"] == "H"
    end

    test "returns empty list for unmatched symbol", %{scene: scene} do
      {:ok, _hub} =
        %Hub{}
        |> Hub.changeset(scene, %{
          name: "Hydrogen Room",
          user_data: %{chemistry: %{symbol: "H"}}
        })
        |> Repo.insert()

      assert Hub.get_element_rooms("Zz", nil).entries == []
    end

    test "is case-sensitive for element symbols", %{scene: scene} do
      {:ok, _hub} =
        %Hub{}
        |> Hub.changeset(scene, %{
          name: "Hydrogen Room",
          user_data: %{chemistry: %{symbol: "H"}}
        })
        |> Repo.insert()

      assert Hub.get_element_rooms("h", nil).entries == []
    end

    test "supports two-character symbols", %{scene: scene} do
      {:ok, _hub} =
        %Hub{}
        |> Hub.changeset(scene, %{
          name: "Iron Room",
          user_data: %{chemistry: %{symbol: "Fe"}}
        })
        |> Repo.insert()

      assert [result] = Hub.get_element_rooms("Fe", nil).entries
      assert result.name == "Iron Room"
    end

    test "returns multiple rooms for the same element", %{scene: scene} do
      {:ok, _hub1} =
        %Hub{}
        |> Hub.changeset(scene, %{
          name: "Hydrogen Lab A",
          user_data: %{chemistry: %{symbol: "H"}}
        })
        |> Repo.insert()

      {:ok, _hub2} =
        %Hub{}
        |> Hub.changeset(scene, %{
          name: "Hydrogen Lab B",
          user_data: %{chemistry: %{symbol: "H"}}
        })
        |> Repo.insert()

      results = Hub.get_element_rooms("H", nil).entries
      assert length(results) == 2
    end

    test "does not match rooms without chemistry data", %{scene: scene} do
      {:ok, _hub} =
        %Hub{}
        |> Hub.changeset(scene, %{name: "Plain Room"})
        |> Repo.insert()

      assert Hub.get_element_rooms("H", nil).entries == []
    end

    test "returns both rooms when querying for the same element", %{scene: scene} do
      {:ok, _hub_a} =
        %Hub{}
        |> Hub.changeset(scene, %{
          name: "Older Room",
          user_data: %{chemistry: %{symbol: "H"}}
        })
        |> Repo.insert()

      {:ok, _hub_b} =
        %Hub{}
        |> Hub.changeset(scene, %{
          name: "Newer Room",
          user_data: %{chemistry: %{symbol: "H"}}
        })
        |> Repo.insert()

      results = Hub.get_element_rooms("H", nil).entries
      assert length(results) == 2
    end
  end
end
