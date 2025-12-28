defmodule TodoApp.Organizations.Workspace do
  use Ecto.Schema
  import Ecto.Changeset

  schema "workspaces" do
    field :name, :string
    field :slug, :string
    field :description, :string
    field :is_default, :boolean, default: false
    
    belongs_to :organization, TodoApp.Organizations.Organization
    has_many :todos, TodoApp.Todos.Todo
    
    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(workspace, attrs) do
    workspace
    |> cast(attrs, [:name, :slug, :description, :is_default, :organization_id])
    |> validate_required([:name, :slug, :organization_id])
    |> validate_format(:slug, ~r/^[a-z0-9-]+$/, 
         message: "must contain only lowercase letters, numbers, and hyphens")
    |> unique_constraint([:organization_id, :slug])
  end
end