defmodule TodoApp.Organizations.Organization do
  use Ecto.Schema
  import Ecto.Changeset

  schema "organizations" do
    field :name, :string
    field :slug, :string
    
    belongs_to :owner, TodoApp.Accounts.User
    has_many :memberships, TodoApp.Organizations.OrganizationMember
    has_many :members, through: [:memberships, :user]
    has_many :workspaces, TodoApp.Organizations.Workspace
    
    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(organization, attrs) do
    organization
    |> cast(attrs, [:name, :slug, :owner_id])
    |> validate_required([:name, :slug, :owner_id])
    |> validate_format(:slug, ~r/^[a-z0-9-]+$/, 
         message: "must contain only lowercase letters, numbers, and hyphens")
    |> unique_constraint(:slug)
  end
end