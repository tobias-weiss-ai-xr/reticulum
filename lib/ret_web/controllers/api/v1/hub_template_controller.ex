defmodule RetWeb.Api.V1.HubTemplateController do
  use RetWeb, :controller
  import RetWeb.ApiHelpers

  alias Ret.{HubTemplate, Repo}
  alias RetWeb.Api.V1.HubTemplateView

  action_fallback RetWeb.Api.V1.FallbackController

  def index(conn, _params) do
    templates = HubTemplate.list_public_templates()
    render(conn, "index.json", templates: templates)
  end

  def user_templates(conn, _params) do
    account = Guardian.Plug.current_resource(conn)
    templates = HubTemplate.list_user_templates(account.account_id)
    render(conn, "index.json", templates: templates)
  end

  def create(conn, params) do
    account = Guardian.Plug.current_resource(conn)

    with {:ok, %HubTemplate{} = template} <- HubTemplate.create_template(params, account) do
      conn
      |> put_status(:created)
      |> render("show.json", template: template)
    end
  end

  def show(conn, %{"id" => template_id}) do
    template = HubTemplate.get_template!(template_id)
    render(conn, "show.json", template: template)
  end

  def update(conn, params) do
    account = Guardian.Plug.current_resource(conn)
    template = HubTemplate.get_template!(params["id"])

    if template.created_by_account_id == account.account_id do
      with {:ok, %HubTemplate{} = template} <- HubTemplate.update_template(template, params) do
        render(conn, "show.json", template: template)
      end
    else
      conn
      |> put_status(:forbidden)
      |> json(%{error: "Not authorized to update this template"})
    end
  end

  def delete(conn, %{"id" => template_id}) do
    account = Guardian.Plug.current_resource(conn)
    template = HubTemplate.get_template!(template_id)

    if template.created_by_account_id == account.account_id do
      with {:ok, %HubTemplate{}} <- HubTemplate.delete_template(template) do
        send_resp(conn, :no_content, "")
      end
    else
      conn
      |> put_status(:forbidden)
      |> json(%{error: "Not authorized to delete this template"})
    end
  end

  def create_from_template(conn, %{"template_id" => template_id, "overrides" => overrides}) do
    account = Guardian.Plug.current_resource(conn)
    template = HubTemplate.get_template!(template_id)

    with {:ok, %Ret.Hub{} = hub} <- HubTemplate.create_hub_from_template(template, account, overrides) do
      conn
      |> put_status(:created)
      |> render("room_created.json", hub: hub)
    end
  end
end
