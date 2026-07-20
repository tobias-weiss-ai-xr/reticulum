defmodule Ret.Repo.Migrations.CreateHubSessions do
  use Ecto.Migration

  def change do
    create table(:hub_sessions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :hub_id, references(:hubs, column: :hub_id, on_delete: :delete_all), null: false
      add :creator_account_id, references(:accounts, column: :account_id, on_delete: :delete_all), null: false
      add :title, :string, null: false
      add :description, :text
      add :start_time, :utc_datetime, null: false
      add :end_time, :utc_datetime, null: false
      add :recurrence_pattern, :string
      add :recurrence_end_date, :date
      add :parent_session_id, references(:hub_sessions, type: :binary_id, on_delete: :delete_all)
      add :state, :string, default: "scheduled"
      add :max_participants, :integer
      add :metadata, :map, default: %{}

      timestamps(type: :utc_datetime)
    end

    create index(:hub_sessions, [:hub_id])
    create index(:hub_sessions, [:creator_account_id])
    create index(:hub_sessions, [:start_time])
    create index(:hub_sessions, [:state])
    create index(:hub_sessions, [:parent_session_id])
  end
end
