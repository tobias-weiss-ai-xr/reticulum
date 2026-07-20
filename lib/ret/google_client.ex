defmodule Ret.GoogleClient do
  @oauth_scope "openid email profile"
  @google_api_base "https://oauth2.googleapis.com"
  @google_user_info_base "https://www.googleapis.com/oauth2/v3"

  def get_oauth_url(hub_sid) do
    authorize_params = %{
      response_type: "code",
      client_id: module_config(:client_id),
      scope: @oauth_scope,
      state: Ret.OAuthToken.token_for_hub(hub_sid),
      redirect_uri: get_redirect_uri(),
      access_type: "offline",
      prompt: "select_account"
    }

    "https://accounts.google.com/o/oauth2/v2/auth?" <> URI.encode_query(authorize_params)
  end

  def fetch_access_token(oauth_code) do
    body = {
      :form,
      [
        client_id: module_config(:client_id),
        client_secret: module_config(:client_secret),
        grant_type: "authorization_code",
        code: oauth_code,
        redirect_uri: get_redirect_uri()
      ]
    }

    "#{@google_api_base}/token"
    |> Ret.HttpUtils.retry_post_until_success(body,
      headers: [{"content-type", "application/x-www-form-urlencoded"}]
    )
    |> Map.get(:body)
    |> Poison.decode!()
    |> Map.get("access_token")
  end

  def fetch_user_info(access_token) do
    "#{@google_user_info_base}/userinfo"
    |> Ret.HttpUtils.retry_get_until_success(
      headers: [{"authorization", "Bearer #{access_token}"}]
    )
    |> Map.get(:body)
    |> Poison.decode!()
  end

  defp get_redirect_uri(), do: RetWeb.Endpoint.url() <> "/api/v1/oauth/google"

  defp module_config(key) do
    Application.get_env(:ret, __MODULE__)[key]
  end
end
