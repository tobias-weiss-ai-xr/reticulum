defmodule Ret.HubTemplate do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  alias Ret.{Account, Hub, HubTemplate, Repo}

  @schema_prefix "ret0"
  @primary_key {:template_id, :id, autogenerate: true}

  def template_preloads do
    [
      created_by_account: []
    ]
  end

  schema "hub_templates" do
    field :name, :string
    field :description, :string
    field :template_sid, :string
    field :is_public, :boolean, default: false
    field :usage_count, :integer, default: 0

    field :max_occupant_count, :integer, default: 0
    field :room_size, :integer, default: 0
    field :spawned_object_types, :integer, default: 0
    field :entry_mode, :string, default: "promiscuous"
    field :default_environment_gltf_bundle_url, :string
    field :member_permissions, :integer, default: 255

    belongs_to :scene, Ret.Scene,
      references: :scene_id,
      on_replace: :nilify

    belongs_to :created_by_account, Ret.Account,
      references: :account_id

    timestamps()
  end

  @required_keys [
    :name,
    :template_sid
  ]

  @permitted_keys [
    :description,
    :is_public,
    :max_occupant_count,
    :room_size,
    :spawned_object_types,
    :entry_mode,
    :default_environment_gltf_bundle_url,
    :member_permissions,
    :scene_id
  ]

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @permitted_keys ++ @required_keys)
    |> validate_required(@required_keys)
    |> validate_length(:name, min: 1, max: 128)
    |> validate_length(:description, max: 512)
    |> validate_inclusion(:entry_mode, ["promiscuous", "lobby", "invite", "deny"])
    |> validate_number(:max_occupant_count, greater_than_or_equal_to: 0)
    |> validate_number(:room_size, greater_than_or_equal_to: 0, less_than_or_equal_to: 2)
    |> unique_constraint(:template_sid)
  end

  def create_template(params, account) do
    %HubTemplate{}
    |> changeset(params)
    |> put_change(:created_by_account, account)
    |> Repo.insert()
  end

  def list_templates do
    HubTemplate
    |> preload([:created_by_account, :scene])
    |> order_by(desc: :usage_count)
    |> Repo.all()
  end

  def list_public_templates do
    HubTemplate
    |> where([t], t.is_public == true)
    |> preload([:created_by_account, :scene])
    |> order_by(desc: :usage_count)
    |> Repo.all()
  end

  def list_user_templates(account_id) do
    HubTemplate
    |> where([t], t.created_by_account_id == ^account_id)
    |> preload([:created_by_account, :scene])
    |> order_by(desc: :inserted_at)
    |> Repo.all()
  end

  def get_template!(template_id) do
    HubTemplate
    |> preload([:created_by_account, :scene])
    |> Repo.get!(template_id)
  end

  def update_template(%HubTemplate{} = template, params) do
    template
    |> changeset(params)
    |> Repo.update()
  end

  def delete_template(%HubTemplate{} = template) do
    Repo.delete(template)
  end

  def increment_usage(%HubTemplate{} = template) do
    template
    |> Ecto.Changeset.change(usage_count: template.usage_count + 1)
    |> Repo.update()
  end

  def create_hub_from_template(%HubTemplate{} = template, account, overrides \\ %{}) do
    hub_params = %{
      name: "#{template.name} (#{DateTime.utc_now() |> DateTime.to_unix()})",
      description: template.description,
      max_occupant_count: template.max_occupant_count,
      room_size: template.room_size,
      spawned_object_types: template.spawned_object_types,
      entry_mode: template.entry_mode,
      member_permissions: template.member_permissions
    }

    hub_params = if template.scene_id do
      Map.put(hub_params, :scene_id, template.scene_id)
    else
      hub_params
    end

    hub_params = Map.merge(hub_params, overrides)

    case Hub.create_room(hub_params, account) do
      {:ok, hub} ->
        increment_usage(template)
        {:ok, hub}
      error ->
        error
    end
  end
end
