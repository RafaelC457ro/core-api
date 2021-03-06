defmodule Herenow.Repo.Migrations.CreateClients do
  use Ecto.Migration

  def change do
    create table(:clients) do
      add :email, :string, size: 254
      add :password, :string, size: 131
      add :is_company, :boolean, default: false
      add :name, :string
      add :legal_name, :string
      add :segment, :string
      add :postal_code, :string, size: 8
      add :street_name, :string
      add :street_number, :string
      add :city, :string
      add :state, :string

      timestamps()
    end

    create unique_index(:clients, [:email])
  end
end
