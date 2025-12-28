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
     |> assign(:search_query, "")
     |> assign(:filter_status, "all")
     |> assign(:selected_tag_ids, [])
     |> assign(:available_tags, if(current_user, do: TodoApp.Tags.list_user_tags(current_user.id), else: []))
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
     |> load_filtered_todos()
     |> assign(:form, to_form(Todos.change_todo(default_todo)))}
  end

  @impl true
  def handle_event("search", %{"search" => search_query}, socket) do
    {:noreply,
     socket
     |> assign(:search_query, search_query)
     |> load_filtered_todos()}
  end

  @impl true
  def handle_event("filter_status", %{"status" => status}, socket) do
    {:noreply,
     socket
     |> assign(:filter_status, status)
     |> load_filtered_todos()}
  end

  @impl true
  def handle_event("toggle_tag", %{"tag_id" => tag_id}, socket) do
    tag_id = String.to_integer(tag_id)
    selected_tag_ids = 
      if tag_id in socket.assigns.selected_tag_ids do
        List.delete(socket.assigns.selected_tag_ids, tag_id)
      else
        [tag_id | socket.assigns.selected_tag_ids]
      end
    
    {:noreply,
     socket
     |> assign(:selected_tag_ids, selected_tag_ids)
     |> load_filtered_todos()}
  end

  @impl true
  def handle_event("clear_filters", _params, socket) do
    {:noreply,
     socket
     |> assign(:search_query, "")
     |> assign(:filter_status, "all")
     |> assign(:selected_tag_ids, [])
     |> load_filtered_todos()}
  end

  @impl true
  def handle_info({:todo_created, _todo}, socket) do
    {:noreply, load_filtered_todos(socket)}
  end

  @impl true
  def handle_info({:todo_updated, _todo}, socket) do
    {:noreply, load_filtered_todos(socket)}
  end

  @impl true
  def handle_info({:todo_deleted, _todo}, socket) do
    {:noreply, load_filtered_todos(socket)}
  end

  defp load_filtered_todos(socket) do
    filters = build_filters(socket)
    todos = Todos.filter_todos(socket.assigns.current_user.id, filters)
    assign(socket, :todos, todos)
  end

  defp build_filters(socket) do
    filters = []
    
    filters = 
      if socket.assigns.search_query != "" do
        [{:search, socket.assigns.search_query} | filters]
      else
        filters
      end
    
    filters = 
      case socket.assigns.filter_status do
        "completed" -> [{:status, "completed"} | filters]
        "incomplete" -> [{:status, "incomplete"} | filters]
        _ -> filters
      end
    
    filters = 
      if socket.assigns.selected_tag_ids != [] do
        [{:tag_ids, socket.assigns.selected_tag_ids} | filters]
      else
        filters
      end
    
    # 日付フィルターを追加
    [{:date, socket.assigns.selected_date} | filters]
  end
end