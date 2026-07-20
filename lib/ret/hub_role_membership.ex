defmodule Ret.HubRoleMembership do
  use Ecto.Schema
  import Ecto.Changeset

  alias Ret.{HubRoleMembership, HubRole}

  @schema_prefix "ret0"
  @primary_key {:hub_role_membership_id, :id, autogenerate: true}

  schema "hub_role_memberships" do
    field :role, Ecto.Enum, values: [:owner, :teacher, :student, :guest]

    belongs_to :hub, Ret.Hub, references: :hub_id
    belongs_to :account, Ret.Account, references: :account_id

    timestamps()
  end

  def changeset(%HubRoleMembership{} = membership, attrs \\ %{}) do
    membership
    |> cast(attrs, [:role, :hub_id, :account_id])
    |> validate_required([:role, :hub_id, :account_id])
    |> validate_inclusion(:role, HubRole.roles())
    |> unique_constraint([:hub_id, :account_id], name: :hub_role_memberships_hub_id_account_id_index)
  end

  def create_membership(hub, account, role) do
    %HubRoleMembership{}
    |> changeset(%{hub_id: hub.hub_id, account_id: account.account_id, role: role})
    |> Repo.insert()
  end

  def update_membership(%HubRoleMembership{} = membership, role) do
    membership
    |> changeset(%{role: role})
    |> Repo.update()
  end

  def delete_membership(%HubRoleMembership{} = membership) do
    Repo.delete(membership)
  end

  def get_membership(hub_id, account_id) do
    Repo.one(from m in HubRoleMembership,
      where: m.hub_id == ^hub_id and m.account_id == ^account_id,
      preload: [:account, :hub])
  end

  def list_memberships(hub_id) do
    Repo.all(from m in HubRoleMembership,
      where: m.hub_id == ^hub_id,
      order_by: [desc: m.inserted_at],
      preload: [:account])
  end

  def get_role_permissions(hub_id, account_id) do
    case get_membership(hub_id, account_id) do
      nil -> HubRole.role_permissions(:guest)
      membership -> HubRole.role_permissions(membership.role)
    end
  end

  def has_permission?(hub_id, account_id, permission) do
    permissions = get_role_permissions(hub_id, account_id)
    Map.get(permissions, permission, false)
  end
end
