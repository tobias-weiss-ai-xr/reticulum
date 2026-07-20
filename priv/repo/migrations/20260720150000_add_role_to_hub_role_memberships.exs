defmodule Ret.Repo.Migrations.AddRoleToHubRoleMemberships do
  use Ecto.Migration

  def up do
    alter table(:hub_role_memberships, prefix: "ret0") do
      add :role, :string
    end

    execute("UPDATE ret0.hub_role_memberships SET role = 'owner' WHERE role IS NULL")

    alter table(:hub_role_memberships, prefix: "ret0") do
      modify :role, :string, null: false
    end

    create index(:hub_role_memberships, [:role], prefix: "ret0")
  end

  def down do
    drop index(:hub_role_memberships, [:role], prefix: "ret0")

    alter table(:hub_role_memberships, prefix: "ret0") do
      remove :role
    end
  end
end