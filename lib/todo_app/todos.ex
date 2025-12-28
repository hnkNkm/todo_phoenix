defmodule TodoApp.Todos do
  @moduledoc """
  The Todos context.
  """

  import Ecto.Query, warn: false
  alias TodoApp.Repo
  alias TodoApp.Todos.Todo

  @doc """
  Returns the list of todos for a specific user in a workspace.
  """
  def list_workspace_todos(workspace_id, user_id) do
    Todo
    |> where(workspace_id: ^workspace_id, user_id: ^user_id)
    |> order_by([desc: :inserted_at])
    |> Repo.all()
  end
  
  @doc """
  Returns the list of todos for a specific user.
  """
  def list_user_todos(user_id) do
    Todo
    |> where(user_id: ^user_id)
    |> order_by([desc: :inserted_at])
    |> Repo.all()
  end

  @doc """
  Gets a single todo for a specific user.
  """
  def get_user_todo!(user_id, id) do
    Todo
    |> where(user_id: ^user_id, id: ^id)
    |> Repo.one!()
  end

  @doc """
  Creates a todo.
  """
  def create_todo(attrs \\ %{}) do
    %Todo{}
    |> Todo.changeset(attrs)
    |> Repo.insert()
    |> broadcast(:todo_created)
  end

  @doc """
  Updates a todo.
  """
  def update_todo(%Todo{} = todo, attrs) do
    todo
    |> Todo.changeset(attrs)
    |> Repo.update()
    |> broadcast(:todo_updated)
  end

  @doc """
  Deletes a todo.
  """
  def delete_todo(%Todo{} = todo) do
    Repo.delete(todo)
    |> broadcast(:todo_deleted)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking todo changes.
  """
  def change_todo(%Todo{} = todo, attrs \\ %{}) do
    Todo.changeset(todo, attrs)
  end

  # PubSub for real-time updates
  defp broadcast({:error, _reason} = error, _event), do: error
  defp broadcast({:ok, todo}, event) do
    Phoenix.PubSub.broadcast(TodoApp.PubSub, "todos:#{todo.user_id}", {event, todo})
    {:ok, todo}
  end
end