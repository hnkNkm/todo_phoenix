defmodule TodoApp.Organizations.OrganizationMember do
  use Ecto.Schema
  import Ecto.Changeset

  schema "organization_members" do
    field :role, :string, default: "member"
    
    belongs_to :organization, TodoApp.Organizations.Organization
    belongs_to :user, TodoApp.Accounts.User
    
    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(member, attrs) do
    member
    |> cast(attrs, [:role, :organization_id, :user_id])
    |> validate_required([:role, :organization_id, :user_id])
    |> validate_inclusion(:role, ["owner", "admin", "member"])
    |> unique_constraint([:organization_id, :user_id])
  end
end