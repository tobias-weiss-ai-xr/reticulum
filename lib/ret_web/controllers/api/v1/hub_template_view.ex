defmodule RetWeb.Api.V1.HubTemplateView do
  use RetWeb, :view
  alias RetWeb.Api.V1.HubTemplateView

  def render("index.json", %{templates: templates}) do
    %{
      data: render_many(templates, HubTemplateView, "template.json"),
      total: length(templates)
    }
  end

  def render("show.json", %{template: template}) do
    %{data: render_one(template, HubTemplateView, "template.json")}
  end

  def render("room_created.json", %{hub: hub}) do
    %{
      data: %{
        hub_sid: hub.hub_sid,
        name: hub.name,
        description: hub.description,
        created_at: hub.inserted_at
      }
    }
  end

  def render("template.json", %{template: template}) do
    %{
      id: template.template_id,
      template_sid: template.template_sid,
      name: template.name,
      description: template.description,
      is_public: template.is_public,
      usage_count: template.usage_count,
      max_occupant_count: template.max_occupant_count,
      room_size: room_size_label(template.room_size),
      entry_mode: template.entry_mode,
      created_by: template.created_by_account |> then(fn
        nil -> "Unknown"
        acc -> acc.display_name || acc.email
      end),
      created_at: template.inserted_at,
      has_scene: !is_nil(template.scene_id)
    }
  end

  defp room_size_label(0), do: "small"
  defp room_size_label(1), do: "medium"
  defp room_size_label(2), do: "large"
  defp room_size_label(_), do: "small"
end
