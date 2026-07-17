defmodule Ret.ConnUtils do
  def matches_host(_conn, nil), do: false
  def matches_host(_conn, ""), do: false
  def matches_host(conn, host), do: Regex.match?(~r/\A#{conn.host}\z/i, host)

  @doc """
  Returns the user-agent family from a conn.
  Replaces UAParser.parse/1 which was removed (yamerl OTP 23 incompatibility).
  Supports: "Safari", "Mobile Safari", "Chrome", "Firefox", or "Other".
  """
  def user_agent_family(conn) do
    ua = conn |> Plug.Conn.get_req_header("user-agent") |> List.first() || ""

    cond do
      ua == "" -> "Other"
      String.contains?(ua, "Chrome") || String.contains?(ua, "Chromium") ->
        if String.contains?(ua, "Android") || String.contains?(ua, "iPhone") || String.contains?(ua, "iPad") do
          "Mobile Safari"
        else
          "Chrome"
        end
      String.contains?(ua, "Safari") ->
        if String.contains?(ua, "iPhone") || String.contains?(ua, "iPad") || String.contains?(ua, "iPod") do
          "Mobile Safari"
        else
          "Safari"
        end
      String.contains?(ua, "Firefox") -> "Firefox"
      true -> "Other"
    end
  end

  @doc """
  Returns the OS family from a conn.
  Replaces UAParser.parse/1 which was removed (yamerl OTP 23 incompatibility).
  Returns: "Android", "iOS", or "Other".
  """
  def user_agent_os(conn) do
    ua = conn |> Plug.Conn.get_req_header("user-agent") |> List.first() || ""

    cond do
      String.contains?(ua, "Android") -> "Android"
      String.contains?(ua, "iPhone") || String.contains?(ua, "iPad") || String.contains?(ua, "iPod") -> "iOS"
      String.contains?(ua, "iOS") -> "iOS"
      String.contains?(ua, "like Mac OS X") && String.contains?(ua, "Mobile") -> "iOS"
      true -> "Other"
    end
  end
end
