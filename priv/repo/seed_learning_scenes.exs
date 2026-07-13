# Seed learning scenes from local GLB files.
# Run with: mix run priv/repo/seed_learning_scenes.exs

alias Ret.{Repo, Scene, SceneListing, Storage, OwnedFile, Account}
import Ecto.Query

account =
  Ret.Account
  |> where([a], a.is_admin == true and a.state == :enabled)
  |> limit(1)
  |> Repo.one!()

IO.puts("Seeding learning scenes for account ##{account.account_id}")

existing =
  Scene
  |> Repo.get_by(name: "Wasserstoff - H2 Lernszene")
  |> Repo.preload(Scene.scene_preloads())

if existing do
  IO.puts("  Scene 'Wasserstoff - H2' already exists (##{existing.scene_id}), skipping.")

  unless Repo.get_by(SceneListing, scene_id: existing.scene_id) do
    {:ok, _listing} =
      %SceneListing{}
      |> SceneListing.changeset_for_listing_for_scene(existing, %{
        slug: "wasserstoff-h2",
        tags: %{tags: ["learning", "hydrogen"]}
      })
      |> Repo.insert()

    IO.puts("  -> SceneListing created with tags: learning, hydrogen")
  end
else
  h2_glb_path = Path.expand("../../learning-scenes/hydrogen/h2.glb", __DIR__)

  unless File.exists?(h2_glb_path) do
    IO.puts("ERROR: #{h2_glb_path} not found. Run generate-molecule.js first.")
    System.halt(1)
  end

  content_length = File.stat!(h2_glb_path).size
  IO.puts("Reading H₂ GLB (#{content_length} bytes)...")

  model_key = SecureRandom.hex()
  {:ok, model_uuid} = Storage.store(h2_glb_path, "model/gltf-binary", model_key, nil, Storage.owned_file_path())

  model_owned_file =
    %OwnedFile{}
    |> OwnedFile.changeset(account, %{
      owned_file_uuid: model_uuid,
      key: model_key,
      content_type: "model/gltf-binary",
      content_length: content_length
    })
    |> Repo.insert!()

  IO.puts("  -> Model OwnedFile ##{model_owned_file.owned_file_id} created")

  screenshot_path = Path.expand("../../learning-scenes/hydrogen/screenshot.png", __DIR__)

  unless File.exists?(screenshot_path) do
    minimal_png = :binary.list_to_bin([
      0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
      0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
      0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
      0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53,
      0xDE, 0x00, 0x00, 0x00, 0x0C, 0x49, 0x44, 0x41,
      0x54, 0x08, 0xD7, 0x63, 0xD8, 0xAC, 0x51, 0x00,
      0x00, 0x00, 0x28, 0x00, 0x01, 0x81, 0x3E, 0xA4,
      0xF3, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E,
      0x44, 0xAE, 0x42, 0x60, 0x82
    ])
    File.write!(screenshot_path, minimal_png)
  end

  screenshot_key = SecureRandom.hex()
  {:ok, screenshot_uuid} = Storage.store(screenshot_path, "image/png", screenshot_key, nil, Storage.owned_file_path())

  screenshot_owned_file =
    %OwnedFile{}
    |> OwnedFile.changeset(account, %{
      owned_file_uuid: screenshot_uuid,
      key: screenshot_key,
      content_type: "image/png",
      content_length: File.stat!(screenshot_path).size
    })
    |> Repo.insert!()

  IO.puts("  -> Screenshot OwnedFile ##{screenshot_owned_file.owned_file_id} created")

  {:ok, scene} =
    %Scene{}
    |> Scene.changeset(account, model_owned_file, screenshot_owned_file, nil, %{
      name: "Wasserstoff - H2 Lernszene",
      description: "Interaktive 3D-Lernszene fuer das Element Wasserstoff (H2). Zeigt ein Wasserstoffmolekuel mit Atom- und Bindungsmodell.",
      allow_remixing: true,
      allow_promotion: true,
      attributions: %{"extras" => "Generated with hubs-compose molecule generator"}
    })
    |> Repo.insert()

  scene = Repo.preload(scene, Scene.scene_preloads())
  IO.puts("  -> Scene ##{scene.scene_id} created: '#{scene.name}'")

  {:ok, _listing} =
    %SceneListing{}
    |> SceneListing.changeset_for_listing_for_scene(scene, %{
      slug: "wasserstoff-h2",
      tags: %{tags: ["learning", "hydrogen"]}
    })
    |> Repo.insert()

  IO.puts("  -> SceneListing created with tags: learning, hydrogen")
end

IO.puts("\nDone! Learning scene seeded.")
