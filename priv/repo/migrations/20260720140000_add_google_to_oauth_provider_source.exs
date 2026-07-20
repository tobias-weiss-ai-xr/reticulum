defmodule Ret.Repo.Migrations.AddGoogleToOauthProviderSource do
  use Ecto.Migration

  def up do
    execute("ALTER TYPE ret0.oauth_provider_source ADD VALUE IF NOT EXISTS 'google'")
  end

  def down do
    :ok
  end
end
