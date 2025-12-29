defmodule TodoAppWeb.NotificationBellLive do
  use TodoAppWeb, :live_view
  alias TodoApp.Notifications

  @impl true
  def mount(_params, session, socket) do
    current_user = get_current_user(session)
    
    if connected?(socket) && current_user do
      Notifications.subscribe(current_user.id)
    end
    
    {:ok,
     socket
     |> assign(:current_user, current_user)
     |> assign(:show_dropdown, false)
     |> assign(:notifications, [])
     |> assign(:unread_count, 0)
     |> load_notifications()}
  end

  @impl true
  def handle_event("toggle_dropdown", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_dropdown, !socket.assigns.show_dropdown)
     |> load_notifications()}
  end

  @impl true
  def handle_event("mark_as_read", %{"id" => id}, socket) do
    notification = Notifications.get_notification!(id, socket.assigns.current_user.id)
    {:ok, _} = Notifications.mark_as_read(notification)
    
    {:noreply, load_notifications(socket)}
  end

  @impl true
  def handle_event("mark_all_as_read", _params, socket) do
    Notifications.mark_all_as_read(socket.assigns.current_user.id)
    
    {:noreply, load_notifications(socket)}
  end

  @impl true
  def handle_event("delete_notification", %{"id" => id}, socket) do
    notification = Notifications.get_notification!(id, socket.assigns.current_user.id)
    {:ok, _} = Notifications.delete_notification(notification)
    
    {:noreply, load_notifications(socket)}
  end

  @impl true
  def handle_info({:notification_created, notification}, socket) do
    {:noreply,
     socket
     |> put_flash(:info, notification.title)
     |> load_notifications()
     |> push_event("new_notification", %{
       title: notification.title,
       body: notification.body
     })}
  end

  defp load_notifications(socket) do
    if socket.assigns.current_user do
      notifications = Notifications.list_user_notifications(socket.assigns.current_user.id, limit: 10)
      unread_count = Notifications.unread_count(socket.assigns.current_user.id)
      
      socket
      |> assign(:notifications, notifications)
      |> assign(:unread_count, unread_count)
    else
      socket
    end
  end

  defp get_current_user(session) do
    case session["user_token"] && TodoApp.Accounts.get_user_by_session_token(session["user_token"]) do
      {user, _token_inserted_at} -> user
      nil -> nil
    end
  end

  defp format_time(datetime) do
    now = DateTime.utc_now()
    diff_seconds = DateTime.diff(now, datetime, :second)
    
    cond do
      diff_seconds < 60 ->
        "たった今"
      diff_seconds < 3600 ->
        "#{div(diff_seconds, 60)}分前"
      diff_seconds < 86400 ->
        "#{div(diff_seconds, 3600)}時間前"
      diff_seconds < 604800 ->
        "#{div(diff_seconds, 86400)}日前"
      true ->
        Calendar.strftime(datetime, "%m月%d日")
    end
  end
end