defmodule TodoApp.Repo.Migrations.CreateTags do
  use Ecto.Migration

  def change do
    create table(:tags) do
      add :name, :string, null: false
      add :color, :string, default: "#6366f1"
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:tags, [:name, :user_id])
    create index(:tags, [:user_id])

    # todos_tagsの中間テーブル
    create table(:todos_tags, primary_key: false) do
      add :todo_id, references(:todos, on_delete: :delete_all), null: false
      add :tag_id, references(:tags, on_delete: :delete_all), null: false
      add :inserted_at, :utc_datetime, null: false
    end

    create index(:todos_tags, [:todo_id])
    create index(:todos_tags, [:tag_id])
    create unique_index(:todos_tags, [:todo_id, :tag_id])
  end
end