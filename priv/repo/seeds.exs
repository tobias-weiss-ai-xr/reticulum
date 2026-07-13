# Script for populating the database with default Hubs scenes.
# Run with: mix run priv/repo/seeds.exs
#
# This imports all default scene listings from demo.hubsfoundation.org,
# creates local Scene and SceneListing records, and assigns random
# default scenes to existing hubs that have no scene.

alias Ret.{Repo, Scene, SceneListing, Hub, Avatar, AvatarListing}
import Ecto.Query

# Source of default scene listings
source_host = "https://demo.hubsfoundation.org"

# All 15 scene listing SIDs from demo.hubsfoundation.org
scene_sids = [
  {"vTs21oy", "Winter Cheer"},
  {"l0UhRmS", "Events Promenade"},
  {"8EdNQ5Y", "Outdoor Festival"},
  {"ULnzfkr", "Cliffside Retreat"},
  {"y3Xmyft", "Events Conference Sunrise"},
  {"Z7gRMsp", "Synthcity"},
  {"tPqmlJn", "IF Hub"},
  {"UTnwvxC", "Hubs Maze"},
  {"ysrpCgh", "Spiral Tower"},
  {"OD5HaKB", "Space Gallery"},
  {"p7CqZlR", "Corn Maze"},
  {"xF72cnG", "Hubs Float Park"},
  {"wPVSHaU", "u. r. here"},
  {"nml9ZYH", "Whatever"},
  {"mS1AMdp", "The Nightclub"}
]

# Get the first admin account to own the imported scenes
account =
  Ret.Account
  |> where([a], a.is_admin == true and a.state == :enabled)
  |> limit(1)
  |> Repo.one!()

IO.puts("Importing scenes for account ##{account.account_id} from #{source_host}")

# Import each scene and create a SceneListing with "default" tag
imported_scenes =
  Enum.map(scene_sids, fn {sid, name} ->
    scene_url = "#{source_host}/api/v1/scenes/#{sid}"

    existing =
      Scene
      |> Repo.get_by(imported_from_host: "demo.hubsfoundation.org", imported_from_sid: sid)
      |> Repo.preload(Scene.scene_preloads())

    scene =
      if existing do
        IO.puts("  Skipping #{name} (#{sid}) - already imported as ##{existing.scene_id}")
        existing
      else
        IO.puts("  Importing #{name} (#{sid})...")
        scene = Scene.import_from_url!(scene_url, account)
        scene = Repo.preload(scene, Scene.scene_preloads())
        IO.puts("    -> Scene ##{scene.scene_id} imported")
        scene
      end

    unless Repo.get_by(SceneListing, scene_id: scene.scene_id) do
      {:ok, _listing} =
        %SceneListing{}
        |> SceneListing.changeset_for_listing_for_scene(scene, %{
          tags: %{tags: ["default"]}
        })
        |> Repo.insert()

      IO.puts("    -> SceneListing created with default tag")
    else
      IO.puts("    -> SceneListing already exists, skipping")
    end

    scene
  end)

# Assign random default scenes to existing hubs that have no scene
hubs_without_scenes =
  Hub
  |> where([h], is_nil(h.scene_id) and is_nil(h.scene_listing_id))
  |> Repo.all()

if length(hubs_without_scenes) > 0 do
  IO.puts("\nAssigning random default scenes to #{length(hubs_without_scenes)} hubs...")

  Enum.each(hubs_without_scenes, fn hub ->
    random_scene = Enum.random(imported_scenes)

    hub
    |> Ecto.Changeset.change(%{
      scene_id: random_scene.scene_id,
      scene_listing_id: nil,
      default_environment_gltf_bundle_url: nil
    })
    |> Repo.update!()

    IO.puts("  Hub '#{hub.name}' -> Scene '#{random_scene.name}'")
  end)
else
  IO.puts("\nNo hubs without scenes to update.")
end

IO.puts("\nDone! #{length(scene_sids)} scenes imported/verified.")

avatar_sids = [
  {"wKavX3j", "bot bizness"},
  {"kzvKhlF", "bot black dress"},
  {"aZjcwcm", "bot classic 3PO"},
  {"1QNTko7", "bot Polo 1"},
  {"wmA5giW", "bot sundress"},
  {"FzJ9WKO", "Snowman"},
  {"BvF4nX5", "Snowwoman"},
  {"r5jdIiG", "Alphabet Soup"},
  {"2lHtrxr", "Butternut Soup with Croutons and Bread"},
  {"JUx2YGD", "Tomato Soup with Grilled Cheese"},
  {"N32uUti", "Goat"},
  {"0QX1MLW", "Horse"},
  {"vnWkiSD", "Monkey"},
  {"7nkLNfs", "Ox"},
  {"W86OiTr", "Pig"},
  {"q5T6XKc", "Rat"},
  {"FNB84Bx", "Rooster"},
  {"BrKVX2B", "Snake"},
  {"QbThTIm", "Tiger"},
  {"NGJaC8k", "Dragon"},
  {"aI0ehh3", "Rabbit"},
  {"ny8BUXQ", "Dog"},
  {"ghm9KZB", "Ghostea"},
  {"z9cm3wA", "Ghostea Witch"}
]

IO.puts("\nImporting avatars for account ##{account.account_id} from #{source_host}")

Enum.each(avatar_sids, fn {sid, name} ->
  avatar_url = "#{source_host}/api/v1/avatars/#{sid}"

  existing =
    Avatar
    |> Repo.get_by(imported_from_host: "demo.hubsfoundation.org", imported_from_sid: sid)
    |> Repo.preload(Avatar.file_columns())

  if existing do
    IO.puts("  Skipping #{name} (#{sid}) - already imported")
  else
    IO.puts("  Importing #{name} (#{sid})...")
    avatar = Avatar.import_from_url!(avatar_url, account)
    IO.puts("    -> Avatar ##{avatar.avatar_id} imported")

    unless Repo.get_by(AvatarListing, avatar_id: avatar.avatar_id) do
      {:ok, _listing} =
        %AvatarListing{}
        |> AvatarListing.changeset_for_listing_for_avatar(avatar, %{})
        |> Repo.insert()

      IO.puts("    -> AvatarListing created")
    else
      IO.puts("    -> AvatarListing already exists, skipping")
    end
  end
end)

IO.puts("\nDone! #{length(avatar_sids)} avatars imported/verified.")
