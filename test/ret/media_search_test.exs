defmodule Ret.MediaSearchTest do
  use Ret.DataCase, async: true
  import Ret.TestHelpers

  alias Ret.{Repo, SceneListing, Scene, MediaSearch, MediaSearchQuery}

  setup do
    account = create_account("media_search_test")
    scene = create_scene(account)
    create_scene_listing(%{scene: scene})
    {:ok, account: account, scene: scene}
  end

  describe "search scene_listings" do
    test "returns all scene listings without filter" do
      assert {:commit, %{entries: [_ | _]}} =
               MediaSearch.search(%MediaSearchQuery{
                 source: "scene_listings",
                 cursor: "1",
                 q: nil,
                 filter: nil
               })
    end

    test "returns matching scene listings for a tag filter" do
      assert {:commit, %{entries: entries}} =
               MediaSearch.search(%MediaSearchQuery{
                 source: "scene_listings",
                 cursor: "1",
                 q: nil,
                 filter: "foo"
               })

      assert length(entries) > 0
    end

    test "returns empty when tag filter matches nothing" do
      assert {:commit, %{entries: entries}} =
               MediaSearch.search(%MediaSearchQuery{
                 source: "scene_listings",
                 cursor: "1",
                 q: nil,
                 filter: "nonexistent_tag_xyz"
               })

      assert entries == []
    end

    test "filters by featured tag" do
      # The seeded data doesn't have "featured" tags, so this should be empty
      assert {:commit, %{entries: entries}} =
               MediaSearch.search(%MediaSearchQuery{
                 source: "scene_listings",
                 cursor: "1",
                 q: nil,
                 filter: "featured"
               })

      assert entries == []
    end

    test "searches by name query" do
      assert {:commit, %{entries: entries}} =
               MediaSearch.search(%MediaSearchQuery{
                 source: "scene_listings",
                 cursor: "1",
                 q: "Test",
                 filter: nil
               })

      assert length(entries) > 0
      assert Enum.any?(entries, fn e -> String.contains?(e.name, "Test") end)
    end

    test "does not include delisted scenes" do
      scene = Repo.get_by(Scene, name: "Test Scene")
      listing = Repo.get_by(SceneListing, scene_id: scene.scene_id)

      Repo.update_all(
        from(l in SceneListing, where: l.scene_listing_id == ^listing.scene_listing_id),
        set: [state: :delisted]
      )

      MediaSearch.search(%MediaSearchQuery{
                   source: "scene_listings",
                   cursor: "1",
                   q: nil,
                   filter: nil
                 })
                 |> elem(1)
                 |> Map.get(:entries)
                 |> then(fn entries ->
                   refute Enum.any?(entries, fn e ->
                     e.id == listing.scene_listing_sid
                   end)
                 end)
    end

    test "returns entries with correct structure" do
      assert {:commit, %{entries: [entry | _]}} =
               MediaSearch.search(%MediaSearchQuery{
                 source: "scene_listings",
                 cursor: "1",
                 q: nil,
                 filter: "foo"
               })

      assert entry.id != nil
      assert entry.name != nil
      assert entry.type == "scene_listing"
      assert entry.images.preview.url != nil
    end
  end
end
