defmodule TodoApp.Organizations do
  @moduledoc """
  The Organizations context.
  """

  import Ecto.Query, warn: false
  alias TodoApp.Repo
  alias TodoApp.Organizations.{Organization, OrganizationMember, Workspace}
  alias TodoApp.Accounts.User
  
  @doc """
  Creates an organization with the given user as owner.
  Also creates a default workspace for the organization.
  """
  def create_organization(%User{} = owner, attrs \\ %{}) do
    Repo.transaction(fn ->
      # Create organization
      org = %Organization{owner_id: owner.id}
      |> Organization.changeset(attrs)
      |> Repo.insert!()
      
      # Add owner as member with owner role
      %OrganizationMember{}
      |> OrganizationMember.changeset(%{
        organization_id: org.id,
        user_id: owner.id,
        role: "owner"
      })
      |> Repo.insert!()
      
      # Create default workspace
      %Workspace{}
      |> Workspace.changeset(%{
        name: "Default",
        slug: "default",
        organization_id: org.id,
        is_default: true
      })
      |> Repo.insert!()
      
      org
    end)
  end
  
  @doc """
  Gets a user's organizations.
  """
  def list_user_organizations(%User{} = user) do
    Organization
    |> join(:inner, [o], m in OrganizationMember, on: m.organization_id == o.id)
    |> where([o, m], m.user_id == ^user.id)
    |> preload(:owner)
    |> Repo.all()
  end
  
  @doc """
  Gets an organization by slug.
  """
  def get_organization_by_slug!(slug) do
    Organization
    |> where(slug: ^slug)
    |> preload([:owner, :workspaces])
    |> Repo.one!()
  end
  
  @doc """
  Gets a workspace by organization and slug.
  """
  def get_workspace!(org_id, workspace_slug) do
    Workspace
    |> where(organization_id: ^org_id, slug: ^workspace_slug)
    |> Repo.one!()
  end
  
  @doc """
  Lists workspaces for an organization.
  """
  def list_organization_workspaces(%Organization{} = org) do
    Workspace
    |> where(organization_id: ^org.id)
    |> order_by([asc: :name])
    |> Repo.all()
  end
  
  @doc """
  Creates a workspace.
  """
  def create_workspace(%Organization{} = org, attrs \\ %{}) do
    %Workspace{organization_id: org.id}
    |> Workspace.changeset(attrs)
    |> Repo.insert()
  end
  
  @doc """
  Checks if a user is a member of an organization.
  """
  def member?(%User{} = user, %Organization{} = org) do
    OrganizationMember
    |> where(user_id: ^user.id, organization_id: ^org.id)
    |> Repo.exists?()
  end
  
  @doc """
  Gets a user's role in an organization.
  """
  def get_user_role(%User{} = user, %Organization{} = org) do
    OrganizationMember
    |> where(user_id: ^user.id, organization_id: ^org.id)
    |> select([m], m.role)
    |> Repo.one()
  end
  
  @doc """
  Adds a member to an organization.
  """
  def add_member(%Organization{} = org, %User{} = user, role \\ "member") do
    %OrganizationMember{}
    |> OrganizationMember.changeset(%{
      organization_id: org.id,
      user_id: user.id,
      role: role
    })
    |> Repo.insert()
  end
  
  @doc """
  Gets or creates a default organization for a user.
  """
  def ensure_user_organization(%User{} = user) do
    case list_user_organizations(user) do
      [] ->
        {:ok, org} = create_organization(user, %{
          name: "#{user.email}'s Organization",
          slug: generate_slug(user.email)
        })
        org
        
      [org | _] ->
        org
    end
  end
  
  defp generate_slug(email) do
    email
    |> String.split("@")
    |> List.first()
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9-]/, "-")
    |> String.slice(0, 30)
  end
end