defmodule Ret.Room.Token do
  @moduledoc """
  Room access token generation and verification.

  Tokens are signed with `Ret.PermsToken` (RS512) and include room-specific claims:
  - `room_id`: the hub_sid of the room being accessed (required)
  - `role`: "teacher" or "student" (defaults to "student")
  - `join_hub`: must be `true` (required by RoomAccessPlug validation)
  - `sub`: the account_id (from PermsToken's subject_for_token)
  - `exp`: token expiry (default 5 minutes)

  Generate a token for a teacher granting room access:
      Ret.Room.Token.generate(account, "abc123", role: "teacher")
  """
  alias Ret.PermsToken

  @default_ttl_seconds 300

  @doc """
  Generates a room access token for the given account and room_id.

  Options:
    - `role`: "teacher" or "student" (default "student")
    - `ttl_seconds`: token lifetime in seconds (default 300)
  """
  @spec generate(Ret.Account.t(), String.t(), keyword()) :: {:ok, String.t(), map()}
  def generate(%Ret.Account{} = account, room_id, opts \\ []) do
    role = Keyword.get(opts, :role, "student")
    ttl = Keyword.get(opts, :ttl_seconds, @default_ttl_seconds)

    claims = %{
      join_hub: true,
      room_id: room_id,
      role: role,
      account_id: to_string(account.account_id),
      aud: :ret_perms
    }

    PermsToken.encode_and_sign(nil, claims,
      ttl: {ttl, :seconds},
      allowed_drift: 60 * 1000
    )
  end

  @doc """
  Verifies and decodes a room access token.

  Returns `{:ok, claims}` on success, or `{:error, reason}` on failure.
  Claims is a map with string keys: room_id, sub, role, exp, join_hub, etc.
  """
  @spec verify(String.t()) :: {:ok, map()} | {:error, term()}
  def verify(token) when is_binary(token) do
    PermsToken.decode_and_verify(token)
  end
end
