defmodule TodoApp.Repo.Migrations.AddUserIdToTodos do
  use Ecto.Migration

  def change do
    # 既存のTodoデータを削除（開発環境のため）
    execute "DELETE FROM todos", ""
    
    alter table(:todos) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
    end

    create index(:todos, [:user_id])
  end
end