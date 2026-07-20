defmodule Ret.HubEnrollment do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, only: [where: 2, where: 3, select: 3, preload: 2]
  import Ecto.Query, only: [from: 2]

  alias Ret.{Hub, Account, Repo}

  @schema_prefix "ret0"
  @primary_key {:hub_enrollment_id, :id, autogenerate: true}

  schema "hub_enrollments" do
    field :role, :string, default: "student"
    field :state, :string, default: "active"

    belongs_to :hub, Hub, references: :hub_id
    belongs_to :account, Account, references: :account_id

    timestamps()
  end

  @required_keys [:hub_id, :account_id]

  def changeset(%Ret.HubEnrollment{} = enrollment, attrs) do
    enrollment
    |> cast(attrs, [:hub_id, :account_id, :role, :state])
    |> validate_required(@required_keys)
    |> validate_inclusion(:role, ["student", "teacher"])
    |> validate_inclusion(:state, ["active", "removed"])
    |> unique_constraint(:hub_id, name: :hub_enrollments_hub_id_account_id_index)
    |> foreign_key_constraint(:hub_id)
    |> foreign_key_constraint(:account_id)
  end

  def enroll_account(%Hub{} = hub, %Account{} = account, role \\ "student") do
    %Ret.HubEnrollment{}
    |> changeset(%{hub_id: hub.hub_id, account_id: account.account_id, role: role, state: "active"})
    |> Repo.insert()
  end

  def unenroll_account(%Hub{} = hub, %Account{} = account) do
    case get_enrollment(hub, account) do
      nil -> {:error, :not_enrolled}
      enrollment ->
        enrollment
        |> change(state: "removed")
        |> Repo.update()
    end
  end

  def get_enrollment(%Hub{} = hub, %Account{} = account) do
    Repo.get_by(Ret.HubEnrollment, hub_id: hub.hub_id, account_id: account.account_id, state: "active")
  end

  def list_active_enrollments(%Hub{} = hub) do
    from(e in Ret.HubEnrollment,
      where: e.hub_id == ^hub.hub_id and e.state == "active",
      preload: [:account]
    )
    |> Repo.all()
  end

  def is_enrolled?(%Hub{} = hub, %Account{} = account) do
    case get_enrollment(hub, account) do
      nil -> false
      _ -> true
    end
  end

  def count_students(%Hub{} = hub) do
    from(e in Ret.HubEnrollment,
      where: e.hub_id == ^hub.hub_id and e.state == "active" and e.role == "student",
      select: count(e.hub_enrollment_id)
    )
    |> Repo.one()
  end

  def count_teachers(%Hub{} = hub) do
    from(e in Ret.HubEnrollment,
      where: e.hub_id == ^hub.hub_id and e.state == "active" and e.role == "teacher",
      select: count(e.hub_enrollment_id)
    )
    |> Repo.one()
  end
end
