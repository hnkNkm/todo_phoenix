defmodule TodoApp.Todos.Todo do
  use Ecto.Schema
  import Ecto.Changeset

  schema "todos" do
    field :title, :string
    field :description, :string
    field :completed, :boolean, default: false
    
    belongs_to :user, TodoApp.Accounts.User
    belongs_to :workspace, TodoApp.Organizations.Workspace

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(todo, attrs) do
    todo
    |> cast(attrs, [:title, :description, :completed, :user_id, :workspace_id])
    |> validate_required([:title, :user_id])
  end
end