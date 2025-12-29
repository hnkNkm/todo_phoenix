defmodule TodoApp.Repo.Migrations.AddDescriptionToTodos do
  use Ecto.Migration

  def change do
    alter table(:todos) do
      add :description, :text
    end
  end
end