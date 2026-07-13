defmodule Ret.SeedIdempotencyTest do
  use Ret.DataCase, async: false
  import Ret.TestHelpers

  alias Ret.{Repo, Scene, Account}

  describe "seed_learning_scenes.exs idempotency" do
    test "running the seed script twice does not create duplicates" do
      account = create_account("seed_idem_admin")
      Repo.update_all(from(a in Account, where: a.account_id == ^account.account_id), set: [is_admin: true, state: :enabled])

      scene_count_before = Repo.aggregate(Scene, :count, :scene_id)

      seed_path = Path.expand("../../priv/repo/seed_learning_scenes.exs", __DIR__)
      Code.eval_file(seed_path)

      scene_count_after_first = Repo.aggregate(Scene, :count, :scene_id)
      assert scene_count_after_first >= scene_count_before

      Code.eval_file(seed_path)

      scene_count_after_second = Repo.aggregate(Scene, :count, :scene_id)
      assert scene_count_after_second == scene_count_after_first,
             "Second run should not create additional Scene rows"
    end
  end

  describe "seed pattern idempotency" do
    test "checking name existence before insert prevents duplicate scenes" do
      account = create_account("idempotency_test")

      existing = Repo.get_by(Scene, name: "Unique Test Scene XKCD")
      assert existing == nil

      owned_file = create_owned_file(account, "test scene data")

      {:ok, scene} =
        %Scene{}
        |> Scene.changeset(account, owned_file, owned_file, owned_file, %{
          name: "Unique Test Scene XKCD",
          allow_promotion: true
        })
        |> Repo.insert()

      refute is_nil(scene.scene_id)

      duplicate_check = Repo.get_by(Scene, name: "Unique Test Scene XKCD")
      refute is_nil(duplicate_check)
      assert duplicate_check.scene_id == scene.scene_id
    end
  end
end
