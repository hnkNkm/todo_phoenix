defmodule TodoAppWeb.CalendarLive do
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
    
    {:ok, 
     socket
     |> assign(:current_user, current_user)
     |> assign(:current_date, today)
     |> assign(:selected_date, today)
     |> assign(:view_mode, :month)
     |> assign(:show_calendar, true)
     |> assign(:search_query, "")
     |> assign(:filter_status, "all")
     |> assign(:selected_tag_ids, [])
     |> assign(:available_tags, if(current_user, do: TodoApp.Tags.list_user_tags(current_user.id), else: []))
     |> load_calendar_data()}
  end

  @impl true
  def handle_event("select_date", %{"date" => date_string}, socket) do
    date = Date.from_iso8601!(date_string)
    
    {:noreply,
     socket
     |> assign(:selected_date, date)
     |> load_selected_date_todos()}
  end

  @impl true
  def handle_event("prev_month", _params, socket) do
    new_date = 
      socket.assigns.current_date
      |> Date.beginning_of_month()
      |> Date.add(-1)
    
    {:noreply,
     socket
     |> assign(:current_date, new_date)
     |> load_calendar_data()}
  end

  @impl true
  def handle_event("next_month", _params, socket) do
    new_date = 
      socket.assigns.current_date
      |> Date.end_of_month()
      |> Date.add(1)
    
    {:noreply,
     socket
     |> assign(:current_date, new_date)
     |> load_calendar_data()}
  end

  @impl true
  def handle_event("today", _params, socket) do
    today = Date.utc_today()
    
    {:noreply,
     socket
     |> assign(:current_date, today)
     |> assign(:selected_date, today)
     |> load_calendar_data()}
  end

  @impl true
  def handle_event("toggle_todo", %{"id" => id}, socket) do
    todo = Todos.get_user_todo!(socket.assigns.current_user.id, id)
    {:ok, updated_todo} = Todos.update_todo(todo, %{completed: !todo.completed})
    
    # 繰り返しタスクの場合、完了時に次のタスクを作成
    if updated_todo.completed && updated_todo.is_recurring do
      Todos.create_next_recurring_todo(updated_todo)
    end
    
    {:noreply, load_calendar_data(socket)}
  end

  @impl true
  def handle_event("carry_over_todos", _params, socket) do
    Todos.carry_over_todos(socket.assigns.current_user.id)
    
    {:noreply,
     socket
     |> load_calendar_data()
     |> put_flash(:info, "未完了のタスクを本日に持ち越しました")}
  end

  @impl true
  def handle_event("view_history", _params, socket) do
    {:noreply, assign(socket, :view_mode, :history)}
  end

  @impl true
  def handle_event("view_calendar", _params, socket) do
    {:noreply,
     socket
     |> assign(:view_mode, :month)
     |> load_calendar_data()}
  end

  @impl true
  def handle_event("toggle_calendar", _params, socket) do
    {:noreply, assign(socket, :show_calendar, !socket.assigns.show_calendar)}
  end

  @impl true
  def handle_event("search", %{"search" => search_query}, socket) do
    {:noreply,
     socket
     |> assign(:search_query, search_query)
     |> load_calendar_data()}
  end

  @impl true
  def handle_event("filter_status", %{"status" => status}, socket) do
    {:noreply,
     socket
     |> assign(:filter_status, status)
     |> load_calendar_data()}
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
     |> load_calendar_data()}
  end

  @impl true
  def handle_event("clear_filters", _params, socket) do
    {:noreply,
     socket
     |> assign(:search_query, "")
     |> assign(:filter_status, "all")
     |> assign(:selected_tag_ids, [])
     |> load_calendar_data()}
  end

  @impl true
  def handle_info({:todo_created, _todo}, socket) do
    {:noreply, load_calendar_data(socket)}
  end

  @impl true
  def handle_info({:todo_updated, _todo}, socket) do
    {:noreply, load_calendar_data(socket)}
  end

  @impl true
  def handle_info({:todo_deleted, _todo}, socket) do
    {:noreply, load_calendar_data(socket)}
  end

  defp load_calendar_data(socket) do
    if socket.assigns.current_user do
      start_date = Date.beginning_of_month(socket.assigns.current_date)
      end_date = Date.end_of_month(socket.assigns.current_date)
      
      # フィルターを構築
      filters = build_date_range_filters(socket, start_date, end_date)
      
      # フィルタリングされたタスクを取得
      all_todos = Todos.filter_todos(socket.assigns.current_user.id, filters)
      
      # 日付ごとにグループ化
      todos_by_date = Enum.group_by(all_todos, & &1.due_date)
      
      # 期限切れタスクもフィルタリング
      overdue_filters = build_overdue_filters(socket)
      overdue_todos = Todos.filter_todos(socket.assigns.current_user.id, overdue_filters)
      
      completed_history = 
        if socket.assigns.view_mode == :history do
          Todos.list_completed_todos(socket.assigns.current_user.id, limit: 100)
        else
          []
        end
      
      socket
      |> assign(:todos_by_date, todos_by_date)
      |> assign(:overdue_todos, overdue_todos)
      |> assign(:completed_history, completed_history)
      |> load_selected_date_todos()
    else
      socket
      |> assign(:todos_by_date, %{})
      |> assign(:overdue_todos, [])
      |> assign(:selected_date_todos, [])
      |> assign(:completed_history, [])
    end
  end

  defp load_selected_date_todos(socket) do
    if socket.assigns.current_user do
      filters = build_filters(socket, socket.assigns.selected_date)
      todos = Todos.filter_todos(socket.assigns.current_user.id, filters)
      assign(socket, :selected_date_todos, todos)
    else
      assign(socket, :selected_date_todos, [])
    end
  end

  defp build_filters(socket, date) do
    filters = [{:date, date}]
    
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
    
    filters
  end

  defp build_date_range_filters(socket, start_date, end_date) do
    filters = [{:date_range, {start_date, end_date}}]
    
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
    
    filters
  end

  defp build_overdue_filters(socket) do
    today = Date.utc_today()
    filters = [{:overdue, today}]
    
    filters = 
      if socket.assigns.search_query != "" do
        [{:search, socket.assigns.search_query} | filters]
      else
        filters
      end
    
    filters = 
      if socket.assigns.selected_tag_ids != [] do
        [{:tag_ids, socket.assigns.selected_tag_ids} | filters]
      else
        filters
      end
    
    filters
  end

  defp calendar_days(date) do
    start_date = Date.beginning_of_month(date)
    end_date = Date.end_of_month(date)
    
    # 月の最初の日の曜日を取得 (1=月曜日, 7=日曜日)
    start_weekday = Date.day_of_week(start_date)
    
    # カレンダーの開始日（前月の日付を含む）
    calendar_start = Date.add(start_date, -(start_weekday - 1))
    
    # 6週間分の日付を生成
    for i <- 0..41 do
      Date.add(calendar_start, i)
    end
  end

  defp get_todo_count_for_date(todos_by_date, date) do
    case Map.get(todos_by_date, date, []) do
      [] -> 0
      todos -> length(todos)
    end
  end

  defp get_completed_count_for_date(todos_by_date, date) do
    case Map.get(todos_by_date, date, []) do
      [] -> 0
      todos -> Enum.count(todos, & &1.completed)
    end
  end

  defp format_date(date) do
    Calendar.strftime(date, "%Y年%m月%d日")
  end

  defp format_month(date) do
    Calendar.strftime(date, "%Y年%m月")
  end
end