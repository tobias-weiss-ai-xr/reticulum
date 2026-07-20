defmodule Ret.HubSession do
  @moduledoc """
  Schema for scheduled room sessions. Supports one-time and recurring sessions.
  """
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  alias Ret.{HubSession, Repo}

  @schema_prefix "ret0"
  @primary_key {:id, :binary_id, autogenerate: true}

  schema "hub_sessions" do
    field :hub_id, :integer
    field :creator_account_id, :integer
    field :title, :string
    field :description, :string
    field :start_time, :utc_datetime
    field :end_time, :utc_datetime
    field :recurrence_pattern, :string
    field :recurrence_end_date, :date
    field :parent_session_id, :binary_id
    field :state, :string, default: "scheduled"
    field :max_participants, :integer
    field :metadata, :map, default: %{}

    timestamps(type: :utc_datetime)
  end

  @valid_states ["scheduled", "active", "completed", "cancelled"]
  @valid_recurrence_patterns [nil, "daily", "weekly", "monthly"]

  def changeset(%HubSession{} = hub_session, attrs) do
    hub_session
    |> cast(attrs, [
      :hub_id,
      :creator_account_id,
      :title,
      :description,
      :start_time,
      :end_time,
      :recurrence_pattern,
      :recurrence_end_date,
      :parent_session_id,
      :state,
      :max_participants,
      :metadata
    ])
    |> validate_required([:hub_id, :creator_account_id, :title, :start_time, :end_time])
    |> validate_inclusion(:state, @valid_states)
    |> validate_inclusion(:recurrence_pattern, @valid_recurrence_patterns)
    |> validate_time_range()
    |> validate_recurrence_end_date()
    |> foreign_key_constraint(:hub_id)
    |> foreign_key_constraint(:creator_account_id)
    |> foreign_key_constraint(:parent_session_id)
  end

  defp validate_time_range(changeset) do
    start_time = get_field(changeset, :start_time)
    end_time = get_field(changeset, :end_time)

    if start_time && end_time && end_time <= start_time do
      add_error(changeset, :end_time, "must be after start_time")
    else
      changeset
    end
  end

  defp validate_recurrence_end_date(changeset) do
    recurrence_pattern = get_field(changeset, :recurrence_pattern)
    recurrence_end_date = get_field(changeset, :recurrence_end_date)
    start_time = get_field(changeset, :start_time)

    cond do
      is_nil(recurrence_pattern) and recurrence_end_date ->
        add_error(changeset, :recurrence_end_date, "not allowed for one-time sessions")

      recurrence_end_date && start_time && Date.compare(recurrence_end_date, Date.from_naive!(start_time)) == :lt ->
        add_error(changeset, :recurrence_end_date, "must be on or after start_time")

      true ->
        changeset
    end
  end

  def list_sessions_for_hub(hub_id, filters \\ []) do
    query = from hs in HubSession, where: hs.hub_id == ^hub_id

    query =
      Enum.reduce(filters, query, fn filter, acc ->
        case filter do
          {:state, state} -> from h in acc, where: h.state == ^state
          {:after_time, time} -> from h in acc, where: h.start_time >= ^time
          {:before_time, time} -> from h in acc, where: h.start_time <= ^time
          {:creator, account_id} -> from h in acc, where: h.creator_account_id == ^account_id
        end
      end)

    from h in query, order_by: [desc: h.start_time]
  end

  def get_session!(id), do: Repo.get!(HubSession, id)

  def create_session(attrs) do
    %HubSession{}
    |> changeset(attrs)
    |> Repo.insert()
  end

  def update_session(%HubSession{} = session, attrs) do
    session
    |> changeset(attrs)
    |> Repo.update()
  end

  def cancel_session(%HubSession{} = session) do
    session
    |> changeset(%{state: "cancelled"})
    |> Repo.update()
  end

  def activate_session(%HubSession{} = session) do
    session
    |> changeset(%{state: "active"})
    |> Repo.update()
  end

  def complete_session(%HubSession{} = session) do
    session
    |> changeset(%{state: "completed"})
    |> Repo.update()
  end

  def list_upcoming_sessions(hub_id) do
    from(hs in HubSession,
      where: hs.hub_id == ^hub_id and hs.state == "scheduled" and hs.start_time >= ^NaiveDateTime.utc_now(),
      order_by: [asc: hs.start_time]
    )
    |> Repo.all()
  end
end
