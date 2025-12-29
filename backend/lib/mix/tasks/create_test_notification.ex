defmodule Mix.Tasks.CreateTestNotification do
  use Mix.Task
  alias TodoApp.Notifications

  @shortdoc "Create test notifications for development"
  def run(_) do
    Mix.Task.run("app.start")

    # 最初のユーザーIDを取得（ID: 2のユーザーが存在すると仮定）
    user_id = 2

    # テスト通知を作成
    notifications = [
      %{
        type: "system",
        title: "システムアップデートのお知らせ",
        body: "新機能が追加されました。詳細は設定画面をご確認ください。",
        user_id: user_id,
        action_url: "/users/settings"
      },
      %{
        type: "task_reminder",
        title: "タスクの期限が近づいています",
        body: "「レポート作成」の期限まであと1時間です",
        user_id: user_id,
        action_url: "/todos"
      },
      %{
        type: "task_overdue",
        title: "期限切れのタスクがあります",
        body: "「会議の準備」の期限が過ぎています",
        user_id: user_id,
        action_url: "/todos"
      },
      %{
        type: "achievement",
        title: "達成おめでとうございます！",
        body: "今週のタスク完了数が10件に達しました",
        user_id: user_id
      }
    ]

    Enum.each(notifications, fn notification_attrs ->
      case Notifications.create_notification(notification_attrs) do
        {:ok, notification} ->
          IO.puts("Created notification: #{notification.title}")
        {:error, changeset} ->
          IO.puts("Failed to create notification: #{inspect(changeset.errors)}")
      end
    end)

    IO.puts("\nTest notifications created successfully!")
  end
end