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
  Returns todos for a specific date.
  """
  def list_todos_by_date(user_id, date) do
    Todo
    |> where(user_id: ^user_id, due_date: ^date)
    |> order_by([asc: :inserted_at])
    |> Repo.all()
  end

  @doc """
  Returns todos for a date range.
  """
  def list_todos_by_date_range(user_id, start_date, end_date) do
    Todo
    |> where(user_id: ^user_id)
    |> where([t], t.due_date >= ^start_date and t.due_date <= ^end_date)
    |> order_by([asc: :due_date, asc: :inserted_at])
    |> Repo.all()
  end

  @doc """
  Returns overdue todos that haven't been completed.
  """
  def list_overdue_todos(user_id) do
    today = Date.utc_today()
    
    Todo
    |> where(user_id: ^user_id, completed: false)
    |> where([t], t.due_date < ^today)
    |> order_by([asc: :due_date])
    |> Repo.all()
  end

  @doc """
  Carries over incomplete todos to today.
  """
  def carry_over_todos(user_id) do
    overdue = list_overdue_todos(user_id)
    today = Date.utc_today()
    
    Enum.map(overdue, fn todo ->
      attrs = %{
        due_date: today,
        carried_over_from: todo.due_date,
        carry_over_count: todo.carry_over_count + 1
      }
      update_todo(todo, attrs)
    end)
  end

  @doc """
  Returns completed todos for history view.
  """
  def list_completed_todos(user_id, opts \\ []) do
    limit = Keyword.get(opts, :limit, 50)
    
    Todo
    |> where(user_id: ^user_id, completed: true)
    |> where([t], not is_nil(t.completed_at))
    |> order_by([desc: :completed_at])
    |> limit(^limit)
    |> Repo.all()
  end

  @doc """
  Creates a recurring todo for the next occurrence.
  """
  def create_next_recurring_todo(%Todo{is_recurring: true} = todo) do
    next_date = calculate_next_recurrence(todo.due_date, todo.recurrence_pattern)
    
    attrs = %{
      title: todo.title,
      description: todo.description,
      user_id: todo.user_id,
      workspace_id: todo.workspace_id,
      due_date: next_date,
      is_recurring: true,
      recurrence_pattern: todo.recurrence_pattern
    }
    
    create_todo(attrs)
  end

  def create_next_recurring_todo(_todo), do: {:ok, nil}

  defp calculate_next_recurrence(date, "daily") do
    Date.add(date, 1)
  end

  defp calculate_next_recurrence(date, "weekly") do
    Date.add(date, 7)
  end

  defp calculate_next_recurrence(date, "monthly") do
    Date.add(date, 30)
  end

  defp calculate_next_recurrence(date, _) do
    Date.add(date, 1)
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