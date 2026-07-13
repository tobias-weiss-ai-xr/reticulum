defmodule RetWeb.PrometheusMetricsPlug do
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    body = TelemetryMetricsPrometheus.Core.scrape()

    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(200, body)
  end
end
