defmodule RetWeb.Api.V1.RbacController do
  use RetWeb, :controller
  import RetWeb.ApiHelpers

  alias Ret.{HubRoleMembership, HubRole, Repo, Account}
  alias RetWeb.Api.V1.RbacView

  action_fallback RetWeb.Api.V1.FallbackController

  def index(conn, %{"hub_id" => hub_id}) do
    memberships = HubRoleMembership.list_memberships(hub_id)
    render(conn, "index.json", memberships: memberships, hub_id: hub_id)
  end

  def show(conn, %{"hub_id" => hub_id, "account_id" => account_id}) do
    membership = HubRoleMembership.get_membership(hub_id, account_id)
    
    if membership do
      render(conn, "show.json", membership: membership)
    else
      conn
      |> put_status(:not_found)
      |> json(%{error: "Role membership not found"})
    end
  end

  def create(conn, %{"hub_id" => hub_id, "account_id" => account_id, "role" => role}) do
    current_account = Guardian.Plug.current_resource(conn)
    hub_id_int = String.to_integer(hub_id)
    
    current_membership = HubRoleMembership.get_membership(hub_id_int, current_account.account_id)
    current_role = if current_membership, do: current_membership.role, else: :guest
    
    if not HubRole.role_can_assign?(current_role, String.to_atom(role)) do
      conn
      |> put_status(:forbidden)
      |> json(%{error: "Not authorized to assign this role"})
    else
      account = Repo.get(Account, String.to_integer(account_id))
      
      if account do
        hub = %{hub_id: hub_id_int}
        case HubRoleMembership.create_membership(hub, account, String.to_atom(role)) do
          {:ok, membership} ->
            conn
            |> put_status(:created)
            |> render("show.json", membership: membership)
          {:error, changeset} ->
            conn
            |> put_status(:unprocessable_entity)
            |> json(%{errors: changeset |> Ecto.Changeset.traverse_errors(& &1)})
        end
      else
        conn
        |> put_status(:not_found)
        |> json(%{error: "Account not found"})
      end
    end
  end

  def update(conn, %{"hub_id" => hub_id, "account_id" => account_id, "role" => role}) do
    current_account = Guardian.Plug.current_resource(conn)
    hub_id_int = String.to_integer(hub_id)
    
    current_membership = HubRoleMembership.get_membership(hub_id_int, current_account.account_id)
    current_role = if current_membership, do: current_membership.role, else: :guest
    
    if not HubRole.role_can_assign?(current_role, String.to_atom(role)) do
      conn
      |> put_status(:forbidden)
      |> json(%{error: "Not authorized to assign this role"})
    else
      membership = HubRoleMembership.get_membership(hub_id_int, String.to_integer(account_id))
      
      if membership do
        case HubRoleMembership.update_membership(membership, String.to_atom(role)) do
          {:ok, updated_membership} ->
            render(conn, "show.json", membership: updated_membership)
          {:error, changeset} ->
            conn
            |> put_status(:unprocessable_entity)
            |> json(%{errors: changeset |> Ecto.Changeset.traverse_errors(& &1)})
        end
      else
        conn
        |> put_status(:not_found)
        |> json(%{error: "Role membership not found"})
      end
    end
  end

  def delete(conn, %{"hub_id" => hub_id, "account_id" => account_id}) do
    current_account = Guardian.Plug.current_resource(conn)
    hub_id_int = String.to_integer(hub_id)
    
    current_membership = HubRoleMembership.get_membership(hub_id_int, current_account.account_id)
    current_role = if current_membership, do: current_membership.role, else: :guest
    
    membership = HubRoleMembership.get_membership(hub_id_int, String.to_integer(account_id))
    
    if membership do
      can_delete = HubRole.role_can_assign?(current_role, membership.role) or current_role == :owner
      
      if can_delete do
        case HubRoleMembership.delete_membership(membership) do
          {:ok, _} ->
            send_resp(conn, :no_content, "")
          {:error, _} ->
            conn
            |> put_status(:unprocessable_entity)
            |> json(%{error: "Failed to delete role membership"})
        end
      else
        conn
        |> put_status(:forbidden)
        |> json(%{error: "Not authorized to remove this role"})
      end
    else
      conn
      |> put_status(:not_found)
      |> json(%{error: "Role membership not found"})
    end
  end

  def permissions(conn, %{"hub_id" => hub_id, "account_id" => account_id}) do
    hub_id_int = String.to_integer(hub_id)
    permissions = HubRoleMembership.get_role_permissions(hub_id_int, String.to_integer(account_id))
    
    json(conn, %{
      data: %{
        hub_id: hub_id,
        account_id: account_id,
        permissions: permissions
      }
    })
  end
end