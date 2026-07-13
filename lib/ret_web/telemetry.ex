defmodule RetWeb.Telemetry do
  import Telemetry.Metrics

  def metrics do
    [
      distribution("phoenix.endpoint.stop.duration",
        unit: {:native, :millisecond},
        tags: [:method, :path],
        tag_values: &tags/1,
        reporter_options: [buckets: [5, 10, 25, 50, 100, 250, 500, 1000, 2500, 5000]]
      ),
      distribution("phoenix.router_dispatch.stop.duration",
        unit: {:native, :millisecond},
        tags: [:method, :path],
        tag_values: &tags/1,
        reporter_options: [buckets: [5, 10, 25, 50, 100, 250, 500, 1000, 2500, 5000]]
      )
    ]
  end

  defp tags(%{conn: conn}) do
    %{method: conn.method, path: conn.request_path}
  end
end
