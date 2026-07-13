alias Hubs.Repo
alias Hubs.Accounts.User
alias Hubs.Accounts.Identity
alias Hubs.Accounts

# Find admin user
admin = Repo.get_by(User, email: "admin@chemie-lernen.org")
IO.puts("Admin found: #{inspect(admin != nil)}")

if admin do
  IO.puts("Admin ID: #{admin.id}")
  IO.puts("Admin is_admin: #{inspect(Map.get(admin, :is_admin, :not_found))}")

  # Find identity for admin
  identity = Repo.get_by(Identity, user_id: admin.id)
  IO.puts("Identity found: #{inspect(identity != nil)}")
  
  if identity do
    IO.puts("Identity ID: #{identity.id}")
    case Accounts.create_login_token(identity) do
      {:ok, token} ->
        IO.puts("TOKEN: #{token.token}")
      {:error, reason} ->
        IO.puts("Token error: #{inspect(reason)}")
    end
  end
end
