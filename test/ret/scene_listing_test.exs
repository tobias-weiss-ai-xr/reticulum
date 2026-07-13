defmodule Ret.SceneListingTest do
  use Ret.DataCase
  import Ret.TestHelpers

  alias Ret.{Repo, SceneListing, Scene}

  setup [:create_account, :create_owned_file, :create_scene, :create_scene_listing]

  describe "changeset_for_listing_for_scene/3" do
    test "copies name and description from scene by default", %{scene: scene, scene_listing: listing} do
      assert listing.name == scene.name
      assert listing.description == scene.description
    end

    test "uses provided name when given", %{scene: scene} do
      {:ok, listing} =
        %SceneListing{}
        |> SceneListing.changeset_for_listing_for_scene(scene, %{name: "Custom Name"})
        |> Repo.insert()

      assert listing.name == "Custom Name"
    end

    test "copies owned_file IDs from scene", %{scene: scene} do
      {:ok, listing} =
        %SceneListing{}
        |> SceneListing.changeset_for_listing_for_scene(scene, %{})
        |> Repo.insert()

      listing = listing |> Repo.preload([:model_owned_file, :screenshot_owned_file, :scene_owned_file])

      assert listing.model_owned_file.owned_file_id == scene.model_owned_file.owned_file_id
      assert listing.screenshot_owned_file.owned_file_id == scene.screenshot_owned_file.owned_file_id
    end

    test "copies attributions from scene", %{scene: scene} do
      {:ok, listing} =
        %SceneListing{}
        |> SceneListing.changeset_for_listing_for_scene(scene, %{})
        |> Repo.insert()

      assert listing.attributions == scene.attributions
    end

    test "generates a scene_listing_sid automatically", %{scene: scene} do
      {:ok, listing} =
        %SceneListing{}
        |> SceneListing.changeset_for_listing_for_scene(scene, %{})
        |> Repo.insert()

      assert listing.scene_listing_sid != nil
      assert String.length(listing.scene_listing_sid) > 0
    end

    test "sets tags from params", %{scene: scene} do
      {:ok, listing} =
        %SceneListing{}
        |> SceneListing.changeset_for_listing_for_scene(scene, %{
          tags: %{tags: ["default", "featured"]}
        })
        |> Repo.insert()

      assert listing.tags[:tags] == ["default", "featured"]
    end

    test "sets scene_owned_file_id to nil when scene has none", %{account: account} do
      owned_file = generate_temp_owned_file(account)
      {:ok, scene} =
        %Scene{}
        |> Scene.changeset(account, owned_file, owned_file, nil, %{
          name: "Scene without project file",
          allow_promotion: true
        })
        |> Repo.insert()

      scene = scene |> Repo.preload([:model_owned_file, :screenshot_owned_file, :scene_owned_file])

      {:ok, listing} =
        %SceneListing{}
        |> SceneListing.changeset_for_listing_for_scene(scene, %{})
        |> Repo.insert()

      assert listing.scene_owned_file_id == nil
    end
  end

  describe "get_random_default_scene_listing/0" do
    test "returns a listing tagged as default", %{account: account} do
      owned_file = generate_temp_owned_file(account)
      {:ok, scene} =
        %Scene{}
        |> Scene.changeset(account, owned_file, owned_file, owned_file, %{
          name: "Default Scene",
          allow_promotion: true
        })
        |> Repo.insert()

      scene = scene |> Repo.preload([:model_owned_file, :screenshot_owned_file, :scene_owned_file])

      {:ok, _listing} =
        %SceneListing{}
        |> SceneListing.changeset_for_listing_for_scene(scene, %{
          tags: %{tags: ["default"]}
        })
        |> Repo.insert()

      result = SceneListing.get_random_default_scene_listing()
      assert result != nil
      assert result.model_owned_file_id != nil
      assert result.scene != nil
    end

    test "returns nil when no default listings exist" do
      listing = SceneListing.get_random_default_scene_listing()
      assert listing == nil
    end

    test "returns nil when the only default listing is delisted", %{account: account} do
      owned_file = generate_temp_owned_file(account)
      {:ok, scene} =
        %Scene{}
        |> Scene.changeset(account, owned_file, owned_file, owned_file, %{
          name: "Delisted Default",
          allow_promotion: true
        })
        |> Repo.insert()

      scene = scene |> Repo.preload([:model_owned_file, :screenshot_owned_file, :scene_owned_file])

      {:ok, listing} =
        %SceneListing{}
        |> SceneListing.changeset_for_listing_for_scene(scene, %{
          tags: %{tags: ["default"]}
        })
        |> Repo.insert()

      Repo.update_all(
        from(l in SceneListing, where: l.scene_listing_id == ^listing.scene_listing_id),
        set: [state: :delisted]
      )

      result = SceneListing.get_random_default_scene_listing()
      assert result == nil || result.scene_listing_id != listing.scene_listing_id
    end

    test "only returns listings from promoted scenes", %{account: account} do
      owned_file = generate_temp_owned_file(account)

      {:ok, scene} =
        %Scene{}
        |> Scene.changeset(account, owned_file, owned_file, nil, %{
          name: "Unpromoted with default tag",
          allow_promotion: false
        })
        |> Repo.insert()

      scene = scene |> Repo.preload([:model_owned_file, :screenshot_owned_file, :scene_owned_file])

      {:ok, listing} =
        %SceneListing{}
        |> SceneListing.changeset_for_listing_for_scene(scene, %{
          tags: %{tags: ["default"]}
        })
        |> Repo.insert()

      refute scene.allow_promotion
      result = SceneListing.get_random_default_scene_listing()
      assert result == nil || result.scene_listing_id != listing.scene_listing_id
    end

    test "preloads the scene with all preloaded associations", %{account: account} do
      owned_file = generate_temp_owned_file(account)
      {:ok, scene} =
        %Scene{}
        |> Scene.changeset(account, owned_file, owned_file, owned_file, %{
          name: "Preloaded Check Scene",
          allow_promotion: true
        })
        |> Repo.insert()

      scene = scene |> Repo.preload([:model_owned_file, :screenshot_owned_file, :scene_owned_file])

      {:ok, _listing} =
        %SceneListing{}
        |> SceneListing.changeset_for_listing_for_scene(scene, %{
          tags: %{tags: ["default"]}
        })
        |> Repo.insert()

      listing = SceneListing.get_random_default_scene_listing()
      assert listing != nil

      if listing do
        assert listing.scene != nil
        assert listing.scene.model_owned_file != nil
        assert listing.scene.screenshot_owned_file != nil
      end
    end
  end

  describe "has_any_in_filter?/1" do
    test "returns true when listings with given filter exist" do
      assert SceneListing.has_any_in_filter?("biz")
    end

    test "returns false when no listings match filter" do
      refute SceneListing.has_any_in_filter?("nonexistent-filter-tag")
    end
  end

  describe "slug generation" do
    test "generates a unique slug from the name", %{scene: scene} do
      {:ok, listing} =
        %SceneListing{}
        |> SceneListing.changeset_for_listing_for_scene(scene, %{name: "Test Slug Scene"})
        |> Repo.insert()

      assert listing.slug =~ "test-slug-scene"
    end
  end
end
