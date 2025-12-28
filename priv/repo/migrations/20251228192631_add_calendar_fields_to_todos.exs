defmodule TodoApp.Repo.Migrations.AddCalendarFieldsToTodos do
  use Ecto.Migration

  def change do
    alter table(:todos) do
      add :due_date, :date
      add :completed_at, :utc_datetime
      add :carried_over_from, :date
      add :carry_over_count, :integer, default: 0
      add :is_recurring, :boolean, default: false
      add :recurrence_pattern, :string # daily, weekly, monthly
    end

    # インデックス追加（パフォーマンス向上）
    create index(:todos, [:due_date])
    create index(:todos, [:user_id, :due_date])
    create index(:todos, [:completed_at])
  end
end