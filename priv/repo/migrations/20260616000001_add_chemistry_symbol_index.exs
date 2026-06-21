defmodule Ret.Repo.Migrations.AddChemistrySymbolIndex do
  use Ecto.Migration

  def change do
    create index(:hubs, ["(user_data->'chemistry'->>'symbol')"],
           name: :hubs_user_data_chemistry_symbol,
           using: :btree,
           prefix: "ret0"
         )
  end
end
