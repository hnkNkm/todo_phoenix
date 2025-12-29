defmodule TodoAppWeb.NotificationController do
  use TodoAppWeb, :controller
  alias TodoApp.Notifications

  def index(conn, _params) do
    user = conn.assigns.current_scope.user
    notifications = Notifications.list_user_notifications(user.id, limit: 10)
    unread_count = Notifications.unread_count(user.id)
    
    json(conn, %{
      notifications: Enum.map(notifications, &notification_to_json/1),
      unread_count: unread_count
    })
  end

  def mark_as_read(conn, %{"id" => id}) do
    user = conn.assigns.current_scope.user
    notification = Notifications.get_notification!(id, user.id)
    {:ok, _} = Notifications.mark_as_read(notification)
    
    json(conn, %{success: true})
  end

  def mark_all_as_read(conn, _params) do
    user = conn.assigns.current_scope.user
    Notifications.mark_all_as_read(user.id)
    
    json(conn, %{success: true})
  end

  def delete(conn, %{"id" => id}) do
    user = conn.assigns.current_scope.user
    notification = Notifications.get_notification!(id, user.id)
    {:ok, _} = Notifications.delete_notification(notification)
    
    json(conn, %{success: true})
  end

  defp notification_to_json(notification) do
    %{
      id: notification.id,
      type: notification.type,
      title: notification.title,
      body: notification.body,
      read_at: notification.read_at,
      action_url: notification.action_url,
      inserted_at: notification.inserted_at
    }
  end
end