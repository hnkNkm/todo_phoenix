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
    
    today = Date.utc_today()
    # デフォルトで今日の日付を設定
    default_todo = %Todo{due_date: today}
    
    {:ok, 
     socket
     |> assign(:current_user, current_user)
     |> assign(:selected_date, today)
     |> assign(:todos, if(current_user, do: Todos.list_todos_by_date(current_user.id, today), else: []))
     |> assign(:form, to_form(Todos.change_todo(default_todo)))}
  end

  @impl true
  def handle_event("add_todo", %{"todo" => todo_params}, socket) do
    todo_params = Map.put(todo_params, "user_id", socket.assigns.current_user.id)
    case Todos.create_todo(todo_params) do
      {:ok, _todo} ->
        # 作成後も選択中の日付をデフォルトに設定
        default_todo = %Todo{due_date: socket.assigns.selected_date}
        {:noreply,
         socket
         |> assign(:todos, Todos.list_todos_by_date(socket.assigns.current_user.id, socket.assigns.selected_date))
         |> assign(:form, to_form(Todos.change_todo(default_todo)))
         |> put_flash(:info, "タスクを作成しました")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  @impl true
  def handle_event("toggle_todo", %{"id" => id}, socket) do
    todo = Todos.get_user_todo!(socket.assigns.current_user.id, id)
    {:ok, _todo} = Todos.update_todo(todo, %{completed: !todo.completed})
    {:noreply, assign(socket, :todos, Todos.list_todos_by_date(socket.assigns.current_user.id, socket.assigns.selected_date))}
  end

  @impl true
  def handle_event("delete_todo", %{"id" => id}, socket) do
    todo = Todos.get_user_todo!(socket.assigns.current_user.id, id)
    {:ok, _} = Todos.delete_todo(todo)
    {:noreply, assign(socket, :todos, Todos.list_todos_by_date(socket.assigns.current_user.id, socket.assigns.selected_date))}
  end
  
  @impl true
  def handle_event("select_date", %{"date" => date_string}, socket) do
    date = Date.from_iso8601!(date_string)
    default_todo = %Todo{due_date: date}
    
    {:noreply,
     socket
     |> assign(:selected_date, date)
     |> assign(:todos, Todos.list_todos_by_date(socket.assigns.current_user.id, date))
     |> assign(:form, to_form(Todos.change_todo(default_todo)))}
  end

  @impl true
  def handle_info({:todo_created, _todo}, socket) do
    {:noreply, assign(socket, :todos, Todos.list_todos_by_date(socket.assigns.current_user.id, socket.assigns.selected_date))}
  end

  @impl true
  def handle_info({:todo_updated, _todo}, socket) do
    {:noreply, assign(socket, :todos, Todos.list_todos_by_date(socket.assigns.current_user.id, socket.assigns.selected_date))}
  end

  @impl true
  def handle_info({:todo_deleted, _todo}, socket) do
    {:noreply, assign(socket, :todos, Todos.list_todos_by_date(socket.assigns.current_user.id, socket.assigns.selected_date))}
  end
end