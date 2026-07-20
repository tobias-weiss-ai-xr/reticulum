defmodule RetWeb.Api.V1.HubSessionView do
  use RetWeb, :view

  def render("session.json", %{session: session}) do
    %{
      id: session.id |> to_string(),
      hub_id: session.hub_id |> to_string(),
      creator_account_id: session.creator_account_id,
      title: session.title,
      description: session.description,
      start_time: session.start_time |> NaiveDateTime.to_iso8601(),
      end_time: session.end_time |> NaiveDateTime.to_iso8601(),
      recurrence_pattern: session.recurrence_pattern,
      recurrence_end_date: session.recurrence_end_date,
      parent_session_id: session.parent_session_id && to_string(session.parent_session_id),
      state: session.state,
      max_participants: session.max_participants,
      metadata: session.metadata,
      inserted_at: session.inserted_at |> NaiveDateTime.to_iso8601(),
      updated_at: session.updated_at |> NaiveDateTime.to_iso8601()
    }
  end
end
