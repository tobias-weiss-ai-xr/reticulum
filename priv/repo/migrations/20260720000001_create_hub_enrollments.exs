defmodule Ret.Repo.Migrations.CreateHubEnrollments do
  use Ecto.Migration

  def change do
    create table(:hub_enrollments, primary_key: false) do
      add :hub_enrollment_id, :bigserial, primary_key: true
      add :hub_id, references(:hubs, on_delete: :delete_all, column: :hub_id, type: :bigint), null: false
      add :account_id, references(:accounts, on_delete: :delete_all, column: :account_id, type: :bigint), null: false
      add :role, :string, null: false, default: "student"
      add :state, :string, null: false, default: "active"

      timestamps()
    end

    create unique_index(:hub_enrollments, [:hub_id, :account_id],
             name: :hub_enrollments_hub_id_account_id_index
           )

    create index(:hub_enrollments, [:hub_id, :state], name: :hub_enrollments_hub_id_state_index)
    create index(:hub_enrollments, [:account_id, :state],
             name: :hub_enrollments_account_id_state_index
           )
  end
end
