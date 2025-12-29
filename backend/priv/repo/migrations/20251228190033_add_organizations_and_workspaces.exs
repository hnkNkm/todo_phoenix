defmodule TodoApp.Repo.Migrations.AddOrganizationsAndWorkspaces do
  use Ecto.Migration

  def change do
    # Organizations table
    create table(:organizations) do
      add :name, :string, null: false
      add :slug, :string, null: false
      add :owner_id, references(:users, on_delete: :restrict), null: false
      
      timestamps(type: :utc_datetime)
    end
    
    create unique_index(:organizations, [:slug])
    create index(:organizations, [:owner_id])
    
    # Organization memberships
    create table(:organization_members) do
      add :organization_id, references(:organizations, on_delete: :delete_all), null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :role, :string, null: false, default: "member" # owner, admin, member
      
      timestamps(type: :utc_datetime)
    end
    
    create unique_index(:organization_members, [:organization_id, :user_id])
    create index(:organization_members, [:user_id])
    
    # Workspaces/Projects within organizations
    create table(:workspaces) do
      add :name, :string, null: false
      add :slug, :string, null: false
      add :organization_id, references(:organizations, on_delete: :delete_all), null: false
      add :description, :text
      add :is_default, :boolean, default: false, null: false
      
      timestamps(type: :utc_datetime)
    end
    
    create unique_index(:workspaces, [:organization_id, :slug])
    create index(:workspaces, [:organization_id])
    
    # Add workspace_id to todos
    alter table(:todos) do
      add :workspace_id, references(:workspaces, on_delete: :delete_all)
    end
    
    create index(:todos, [:workspace_id])
  end
end