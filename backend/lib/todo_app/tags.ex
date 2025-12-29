defmodule TodoApp.Tags do
  @moduledoc """
  The Tags context.
  """

  import Ecto.Query, warn: false
  alias TodoApp.Repo
  alias TodoApp.Tags.Tag

  @doc """
  Returns the list of tags for a user.
  """
  def list_user_tags(user_id) do
    Tag
    |> where(user_id: ^user_id)
    |> order_by([asc: :name])
    |> Repo.all()
  end

  @doc """
  Gets a single tag.
  """
  def get_tag!(id), do: Repo.get!(Tag, id)

  @doc """
  Gets a single tag for a specific user.
  """
  def get_user_tag!(user_id, id) do
    Tag
    |> where(user_id: ^user_id, id: ^id)
    |> Repo.one!()
  end

  @doc """
  Creates a tag.
  """
  def create_tag(attrs \\ %{}) do
    %Tag{}
    |> Tag.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a tag.
  """
  def update_tag(%Tag{} = tag, attrs) do
    tag
    |> Tag.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a tag.
  """
  def delete_tag(%Tag{} = tag) do
    Repo.delete(tag)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking tag changes.
  """
  def change_tag(%Tag{} = tag, attrs \\ %{}) do
    Tag.changeset(tag, attrs)
  end

  @doc """
  Returns tags used by todos in the given query.
  """
  def get_tags_for_todos(todos) do
    todo_ids = Enum.map(todos, & &1.id)
    
    query = from t in Tag,
      join: tt in "todos_tags", on: tt.tag_id == t.id,
      where: tt.todo_id in ^todo_ids,
      distinct: true,
      order_by: [asc: t.name]
    
    Repo.all(query)
  end
end