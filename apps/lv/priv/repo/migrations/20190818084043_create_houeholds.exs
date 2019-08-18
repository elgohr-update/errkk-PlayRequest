defmodule E.Repo.Migrations.CreateHoueholds do
  use Ecto.Migration

  def change do
    create table(:households) do
      add :household_id, :string
      add :label, :string
      add :is_active, :boolean, default: false, null: false

      timestamps()
    end

    flush()

    create table(:players) do
      add :player_id, :string
      add :label, :string
      add :household_id, references(:households)

      timestamps()
    end

    create unique_index(:players, [:player_id])
    create unique_index(:households, [:household_id])
  end
end
