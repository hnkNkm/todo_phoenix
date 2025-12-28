defmodule TodoApp.Todos.Todo do
  use Ecto.Schema
  import Ecto.Changeset

  schema "todos" do
    field :title, :string
    field :description, :string
    field :completed, :boolean, default: false
    field :due_date, :date
    field :completed_at, :utc_datetime
    field :carried_over_from, :date
    field :carry_over_count, :integer, default: 0
    field :is_recurring, :boolean, default: false
    field :recurrence_pattern, :string
    
    belongs_to :user, TodoApp.Accounts.User
    belongs_to :workspace, TodoApp.Organizations.Workspace

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(todo, attrs) do
    todo
    |> cast(attrs, [:title, :description, :completed, :due_date, :completed_at, 
                    :carried_over_from, :carry_over_count, :is_recurring, 
                    :recurrence_pattern, :user_id, :workspace_id])
    |> validate_required([:title, :user_id])
    |> validate_inclusion(:recurrence_pattern, ["daily", "weekly", "monthly"], 
         message: "must be daily, weekly, or monthly")
    |> maybe_set_completed_at()
  end
  
  defp maybe_set_completed_at(changeset) do
    case get_change(changeset, :completed) do
      true -> put_change(changeset, :completed_at, DateTime.utc_now(:second))
      false -> put_change(changeset, :completed_at, nil)
      _ -> changeset
    end
  end
end