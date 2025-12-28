defmodule TodoAppWeb.TodoLive do
  use TodoAppWeb, :live_view
  alias TodoApp.Todos
  alias TodoApp.Todos.Todo
  alias TodoApp.Accounts

  @impl true
  def mount(_params, session, socket) do
    current_user = 
      case session["user_token"] && Accounts.get_user_by_session_token(session["user_token"]) do
        {user, _token_inserted_at} -> user
        nil -> nil
      end
    
    if connected?(socket) && current_user do
      Phoenix.PubSub.subscribe(TodoApp.PubSub, "todos:#{current_user.id}")
    end
    
    {:ok, 
     socket
     |> assign(:current_user, current_user)
     |> assign(:todos, if(current_user, do: list_user_todos(current_user.id), else: []))
     |> assign(:form, to_form(Todos.change_todo(%Todo{})))}
  end

  @impl true
  def handle_event("add_todo", %{"todo" => todo_params}, socket) do
    todo_params = Map.put(todo_params, "user_id", socket.assigns.current_user.id)
    case Todos.create_todo(todo_params) do
      {:ok, _todo} ->
        {:noreply,
         socket
         |> assign(:todos, list_user_todos(socket.assigns.current_user.id))
         |> assign(:form, to_form(Todos.change_todo(%Todo{})))
         |> put_flash(:info, "タスクを作成しました")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  @impl true
  def handle_event("toggle_todo", %{"id" => id}, socket) do
    todo = Todos.get_user_todo!(socket.assigns.current_user.id, id)
    {:ok, _todo} = Todos.update_todo(todo, %{completed: !todo.completed})
    {:noreply, assign(socket, :todos, list_user_todos(socket.assigns.current_user.id))}
  end

  @impl true
  def handle_event("delete_todo", %{"id" => id}, socket) do
    todo = Todos.get_user_todo!(socket.assigns.current_user.id, id)
    {:ok, _} = Todos.delete_todo(todo)
    {:noreply, assign(socket, :todos, list_user_todos(socket.assigns.current_user.id))}
  end

  @impl true
  def handle_info({:todo_created, _todo}, socket) do
    {:noreply, assign(socket, :todos, list_user_todos(socket.assigns.current_user.id))}
  end

  @impl true
  def handle_info({:todo_updated, _todo}, socket) do
    {:noreply, assign(socket, :todos, list_user_todos(socket.assigns.current_user.id))}
  end

  @impl true
  def handle_info({:todo_deleted, _todo}, socket) do
    {:noreply, assign(socket, :todos, list_user_todos(socket.assigns.current_user.id))}
  end

  defp list_user_todos(user_id) do
    Todos.list_user_todos(user_id)
  end
end