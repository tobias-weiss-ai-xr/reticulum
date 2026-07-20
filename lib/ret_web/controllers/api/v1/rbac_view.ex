defmodule RetWeb.Api.V1.RbacView do
  use RetWeb, :view
  alias RetWeb.Api.V1.RbacView

  def render("index.json", %{memberships: memberships, hub_id: hub_id}) do
    %{
      data: render_many(memberships, RbacView, "membership.json"),
      hub_id: hub_id,
      total: length(memberships)
    }
  end

  def render("show.json", %{membership: membership}) do
    %{data: render_one(membership, RbacView, "membership.json")}
  end

  def render("membership.json", %{membership: membership}) do
    %{
      id: membership.hub_role_membership_id,
      hub_id: membership.hub_id,
      account_id: membership.account_id,
      role: membership.role,
      email: membership.account.email,
      display_name: membership.account.display_name,
      created_at: membership.inserted_at,
      updated_at: membership.updated_at
    }
  end
end