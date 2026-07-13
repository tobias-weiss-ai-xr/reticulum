defmodule RetWeb.HealthController do
  use RetWeb, :controller
  import Ecto.Query

  def index(conn, _params) do
    results = %{
      db: check_db(),
      cache_hubs_index: check_page_cache({:hubs, "index.html"}),
      cache_hubs_hub: check_page_cache({:hubs, "hub.html"}),
      cache_spoke_index: check_page_cache({:spoke, "index.html"}),
      room_routing: check_room_routing()
    }

    all_healthy = results |> Map.values() |> Enum.all?(& &1)

    conn
    |> put_status(if(all_healthy, do: 200, else: 503))
    |> json(%{healthy: all_healthy, checks: results})
  end

  defp check_db do
    if module_config(:check_repo) do
      case Ret.Repo.all(from Ret.Hub, limit: 0) do
        [_ | _] -> true
        [] -> true
        _ -> false
      end
    else
      true
    end
  rescue
    _ -> false
  end

  defp check_page_cache(key) do
    case Cachex.get(:page_chunks, key) do
      {:ok, value} ->
        cond do
          is_list(value) -> length(value) > 0
          is_map(value) and value != %{} -> true
          true -> false
        end

      _ ->
        false
    end
  rescue
    _ -> false
  end

  defp check_room_routing do
    Ret.RoomAssigner.get_available_host("") != nil
  rescue
    _ -> false
  end

  defp module_config(key) do
    Application.get_env(:ret, __MODULE__)[key]
  end
end
