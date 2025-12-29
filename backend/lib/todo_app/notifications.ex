defmodule TodoApp.Notifications do
  @moduledoc """
  The Notifications context.
  """

  import Ecto.Query, warn: false
  alias TodoApp.Repo
  alias TodoApp.Notifications.{Notification, NotificationSettings, PushSubscription}

  # Notification CRUD

  @doc """
  Returns the list of notifications for a user.
  """
  def list_user_notifications(user_id, opts \\ []) do
    unread_only = Keyword.get(opts, :unread_only, false)
    limit = Keyword.get(opts, :limit, 50)

    query = 
      from n in Notification,
        where: n.user_id == ^user_id,
        order_by: [desc: n.inserted_at],
        limit: ^limit,
        preload: [:todo]

    query = if unread_only do
      from n in query, where: is_nil(n.read_at)
    else
      query
    end

    Repo.all(query)
  end

  @doc """
  Gets a single notification.
  """
  def get_notification!(id, user_id) do
    Repo.get_by!(Notification, id: id, user_id: user_id)
    |> Repo.preload(:todo)
  end

  @doc """
  Creates a notification.
  """
  def create_notification(attrs \\ %{}) do
    %Notification{}
    |> Notification.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, notification} ->
        # Broadcast to user's channel for real-time updates
        broadcast_notification(notification)
        {:ok, notification}
      error ->
        error
    end
  end

  @doc """
  Marks a notification as read.
  """
  def mark_as_read(notification) do
    notification
    |> Notification.mark_as_read()
    |> Repo.update()
  end

  @doc """
  Marks all notifications as read for a user.
  """
  def mark_all_as_read(user_id) do
    from(n in Notification,
      where: n.user_id == ^user_id and is_nil(n.read_at)
    )
    |> Repo.update_all(set: [read_at: DateTime.utc_now(:second)])
  end

  @doc """
  Deletes a notification.
  """
  def delete_notification(notification) do
    Repo.delete(notification)
  end

  @doc """
  Returns the count of unread notifications for a user.
  """
  def unread_count(user_id) do
    from(n in Notification,
      where: n.user_id == ^user_id and is_nil(n.read_at),
      select: count(n.id)
    )
    |> Repo.one()
  end

  # Notification Settings

  @doc """
  Gets or creates notification settings for a user.
  """
  def get_or_create_settings(user_id) do
    case Repo.get_by(NotificationSettings, user_id: user_id) do
      nil ->
        %NotificationSettings{}
        |> NotificationSettings.changeset(%{user_id: user_id})
        |> Repo.insert()
      settings ->
        {:ok, settings}
    end
  end

  @doc """
  Updates notification settings.
  """
  def update_settings(settings, attrs) do
    settings
    |> NotificationSettings.changeset(attrs)
    |> Repo.update()
  end

  # Push Subscriptions

  @doc """
  Creates or updates a push subscription.
  """
  def upsert_push_subscription(attrs) do
    %PushSubscription{}
    |> PushSubscription.changeset(attrs)
    |> Repo.insert(
      on_conflict: :replace_all,
      conflict_target: :endpoint
    )
  end

  @doc """
  Gets push subscriptions for a user.
  """
  def list_user_push_subscriptions(user_id) do
    Repo.all(from s in PushSubscription, where: s.user_id == ^user_id)
  end

  @doc """
  Deletes a push subscription.
  """
  def delete_push_subscription(endpoint) do
    case Repo.get_by(PushSubscription, endpoint: endpoint) do
      nil -> {:error, :not_found}
      subscription -> Repo.delete(subscription)
    end
  end

  # Task Notifications

  @doc """
  Creates notifications for upcoming task deadlines.
  """
  def create_task_reminder(todo, minutes_before) do
    hours = div(minutes_before, 60)
    
    time_text = cond do
      hours >= 24 ->
        "#{div(hours, 24)}日"
      hours > 0 ->
        "#{hours}時間"
      true ->
        "#{minutes_before}分"
    end

    create_notification(%{
      type: "task_reminder",
      title: "タスクの期限が近づいています",
      body: "「#{todo.title}」の期限まであと#{time_text}です",
      user_id: todo.user_id,
      todo_id: todo.id,
      action_url: "/todos",
      metadata: %{
        "minutes_before" => minutes_before
      }
    })
  end

  @doc """
  Creates a notification for an overdue task.
  """
  def create_overdue_notification(todo) do
    create_notification(%{
      type: "task_overdue",
      title: "期限切れのタスクがあります",
      body: "「#{todo.title}」の期限が過ぎています",
      user_id: todo.user_id,
      todo_id: todo.id,
      action_url: "/todos",
      metadata: %{}
    })
  end

  # Real-time broadcasting
  defp broadcast_notification(notification) do
    Phoenix.PubSub.broadcast(
      TodoApp.PubSub,
      "notifications:#{notification.user_id}",
      {:notification_created, notification}
    )
  end

  @doc """
  Subscribes to notification updates for a user.
  """
  def subscribe(user_id) do
    Phoenix.PubSub.subscribe(TodoApp.PubSub, "notifications:#{user_id}")
  end
end