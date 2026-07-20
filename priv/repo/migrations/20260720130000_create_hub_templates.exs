defmodule Ret.Repo.Migrations.CreateHubTemplates do
  use Ecto.Migration

  def change do
    create table(:hub_templates, primary_key: false, prefix: "ret0") do
      add :template_id, :bigserial, primary_key: true
      add :name, :string, null: false
      add :description, :text
      add :template_sid, :string, null: false
      add :is_public, :boolean, default: false, null: false
      add :usage_count, :integer, default: 0, null: false

      add :max_occupant_count, :integer, default: 0, null: false
      add :room_size, :integer, default: 0, null: false
      add :spawned_object_types, :integer, default: 0, null: false
      add :entry_mode, :string, default: "promiscuous", null: false
      add :default_environment_gltf_bundle_url, :text
      add :member_permissions, :integer, default: 255, null: false

      add :scene_id, :bigint
      add :created_by_account_id, :bigint, null: false

      timestamps()
    end

    create unique_index(:hub_templates, [:template_sid], prefix: "ret0")
    create index(:hub_templates, [:is_public], prefix: "ret0")
    create index(:hub_templates, [:created_by_account_id], prefix: "ret0")
    create index(:hub_templates, [:usage_count], prefix: "ret0")
  end
end
