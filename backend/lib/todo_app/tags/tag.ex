defmodule TodoApp.Tags.Tag do
  use Ecto.Schema
  import Ecto.Changeset

  schema "tags" do
    field :name, :string
    field :color, :string, default: "#6366f1"
    
    belongs_to :user, TodoApp.Accounts.User
    many_to_many :todos, TodoApp.Todos.Todo, 
      join_through: "todos_tags",
      on_replace: :delete

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(tag, attrs) do
    tag
    |> cast(attrs, [:name, :color, :user_id])
    |> validate_required([:name, :user_id])
    |> validate_length(:name, min: 1, max: 50)
    |> validate_format(:color, ~r/^#[0-9A-Fa-f]{6}$/, 
         message: "must be a valid hex color code")
    |> unique_constraint([:name, :user_id])
  end
end