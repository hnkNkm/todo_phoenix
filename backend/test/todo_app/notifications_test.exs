defmodule TodoApp.NotificationsTest do
  use TodoApp.DataCase
  alias TodoApp.Notifications
  alias TodoApp.Notifications.{Notification, NotificationSettings}
  alias TodoApp.Accounts

  describe "通知の作成と取得" do
    setup do
      # テスト用ユーザーを作成
      {:ok, user} = Accounts.register_user(%{
        email: "test@example.com",
        password: "password123456"
      })
      
      {:ok, user: user}
    end

    test "正常に通知を作成できる", %{user: user} do
      notification_attrs = %{
        type: "task_reminder",
        title: "テスト通知",
        body: "これはテスト通知です",
        user_id: user.id,
        action_url: "/todos"
      }

      assert {:ok, %Notification{} = notification} = 
        Notifications.create_notification(notification_attrs)
      
      assert notification.title == "テスト通知"
      assert notification.body == "これはテスト通知です"
      assert notification.type == "task_reminder"
      assert notification.user_id == user.id
      assert notification.read_at == nil
    end

    test "必須フィールドなしでエラーになる" do
      invalid_attrs = %{
        type: "task_reminder"
        # title と user_id が不足
      }

      assert {:error, changeset} = Notifications.create_notification(invalid_attrs)
      assert "can't be blank" in errors_on(changeset).title
      assert "can't be blank" in errors_on(changeset).user_id
    end

    test "無効な通知タイプでエラーになる", %{user: user} do
      invalid_attrs = %{
        type: "invalid_type",
        title: "テスト",
        user_id: user.id
      }

      assert {:error, changeset} = Notifications.create_notification(invalid_attrs)
      assert "is invalid" in errors_on(changeset).type
    end

    test "ユーザーの通知リストを取得できる", %{user: user} do
      # 3つの通知を作成
      {:ok, _} = Notifications.create_notification(%{
        type: "task_reminder",
        title: "通知1",
        user_id: user.id
      })
      
      {:ok, _} = Notifications.create_notification(%{
        type: "task_overdue",
        title: "通知2",
        user_id: user.id
      })
      
      {:ok, notification3} = Notifications.create_notification(%{
        type: "task_created",
        title: "通知3",
        user_id: user.id
      })

      # 別のユーザーの通知も作成
      {:ok, other_user} = Accounts.register_user(%{
        email: "other@example.com",
        password: "password123456"
      })
      
      {:ok, _} = Notifications.create_notification(%{
        type: "task_reminder",
        title: "他ユーザーの通知",
        user_id: other_user.id
      })

      # ユーザーの通知のみ取得されることを確認
      notifications = Notifications.list_user_notifications(user.id)
      assert length(notifications) == 3
      assert notification3.id in Enum.map(notifications, & &1.id)
    end

    test "未読通知のみ取得できる", %{user: user} do
      {:ok, notification1} = Notifications.create_notification(%{
        type: "task_reminder",
        title: "未読通知1",
        user_id: user.id
      })
      
      {:ok, notification2} = Notifications.create_notification(%{
        type: "task_reminder",
        title: "既読通知",
        user_id: user.id
      })
      
      # notification2を既読にする
      {:ok, _} = Notifications.mark_as_read(notification2)
      
      # 未読のみ取得
      notifications = Notifications.list_user_notifications(user.id, unread_only: true)
      assert length(notifications) == 1
      assert hd(notifications).id == notification1.id
    end
  end

  describe "既読管理" do
    setup do
      {:ok, user} = Accounts.register_user(%{
        email: "test@example.com",
        password: "password123456"
      })
      
      {:ok, notification} = Notifications.create_notification(%{
        type: "task_reminder",
        title: "テスト通知",
        user_id: user.id
      })
      
      {:ok, user: user, notification: notification}
    end

    test "個別の通知を既読にできる", %{notification: notification} do
      assert notification.read_at == nil
      
      {:ok, updated} = Notifications.mark_as_read(notification)
      assert updated.read_at != nil
    end

    test "すべての通知を既読にできる", %{user: user} do
      # 3つの未読通知を作成
      {:ok, _} = Notifications.create_notification(%{
        type: "task_reminder",
        title: "通知1",
        user_id: user.id
      })
      
      {:ok, _} = Notifications.create_notification(%{
        type: "task_reminder",
        title: "通知2",
        user_id: user.id
      })
      
      {:ok, _} = Notifications.create_notification(%{
        type: "task_reminder",
        title: "通知3",
        user_id: user.id
      })
      
      # 未読数を確認
      assert Notifications.unread_count(user.id) == 4  # setup の1つ + 3つ
      
      # すべて既読にする
      {count, _} = Notifications.mark_all_as_read(user.id)
      assert count == 4
      
      # 未読数が0になることを確認
      assert Notifications.unread_count(user.id) == 0
    end

    test "未読通知数を正しくカウントできる", %{user: user} do
      # 初期状態で1つの未読通知（setupで作成）
      assert Notifications.unread_count(user.id) == 1
      
      # 2つ追加
      {:ok, _} = Notifications.create_notification(%{
        type: "task_reminder",
        title: "追加通知1",
        user_id: user.id
      })
      
      {:ok, notification2} = Notifications.create_notification(%{
        type: "task_reminder",
        title: "追加通知2",
        user_id: user.id
      })
      
      assert Notifications.unread_count(user.id) == 3
      
      # 1つ既読にする
      {:ok, _} = Notifications.mark_as_read(notification2)
      assert Notifications.unread_count(user.id) == 2
    end
  end

  describe "通知の削除" do
    setup do
      {:ok, user} = Accounts.register_user(%{
        email: "test@example.com",
        password: "password123456"
      })
      
      {:ok, notification} = Notifications.create_notification(%{
        type: "task_reminder",
        title: "削除テスト通知",
        user_id: user.id
      })
      
      {:ok, user: user, notification: notification}
    end

    test "通知を削除できる", %{user: user, notification: notification} do
      assert {:ok, %Notification{}} = Notifications.delete_notification(notification)
      
      notifications = Notifications.list_user_notifications(user.id)
      assert length(notifications) == 0
    end
  end

  describe "通知設定" do
    setup do
      {:ok, user} = Accounts.register_user(%{
        email: "test@example.com",
        password: "password123456"
      })
      
      {:ok, user: user}
    end

    test "ユーザーの通知設定を作成・取得できる", %{user: user} do
      {:ok, settings} = Notifications.get_or_create_settings(user.id)
      
      assert %NotificationSettings{} = settings
      assert settings.user_id == user.id
      assert settings.browser_enabled == true
      assert settings.email_enabled == false
      assert settings.reminder_minutes_before == [60, 1440]
    end

    test "通知設定を更新できる", %{user: user} do
      {:ok, settings} = Notifications.get_or_create_settings(user.id)
      
      update_attrs = %{
        browser_enabled: false,
        email_enabled: true,
        reminder_minutes_before: [30, 60, 120]
      }
      
      {:ok, updated} = Notifications.update_settings(settings, update_attrs)
      
      assert updated.browser_enabled == false
      assert updated.email_enabled == true
      assert updated.reminder_minutes_before == [30, 60, 120]
    end
  end

  describe "タスク関連通知" do
    setup do
      {:ok, user} = Accounts.register_user(%{
        email: "test@example.com",
        password: "password123456"
      })
      
      # テスト用のTodoを作成
      {:ok, todo} = TodoApp.Todos.create_todo(%{
        title: "テストタスク",
        description: "テストの説明",
        user_id: user.id,
        due_date: Date.utc_today()
      })
      
      {:ok, user: user, todo: todo}
    end

    test "タスクリマインダー通知を作成できる", %{user: user, todo: todo} do
      {:ok, notification} = Notifications.create_task_reminder(todo, 60)
      
      assert notification.type == "task_reminder"
      assert notification.title == "タスクの期限が近づいています"
      assert notification.body =~ "「テストタスク」の期限まであと1時間です"
      assert notification.user_id == user.id
      assert notification.todo_id == todo.id
      assert notification.action_url == "/todos"
    end

    test "期限切れ通知を作成できる", %{user: user, todo: todo} do
      {:ok, notification} = Notifications.create_overdue_notification(todo)
      
      assert notification.type == "task_overdue"
      assert notification.title == "期限切れのタスクがあります"
      assert notification.body =~ "「テストタスク」の期限が過ぎています"
      assert notification.user_id == user.id
      assert notification.todo_id == todo.id
    end

    test "時間表示が正しくフォーマットされる", %{todo: todo} do
      # 30分前
      {:ok, notification1} = Notifications.create_task_reminder(todo, 30)
      assert notification1.body =~ "30分"
      
      # 2時間前
      {:ok, notification2} = Notifications.create_task_reminder(todo, 120)
      assert notification2.body =~ "2時間"
      
      # 2日前
      {:ok, notification3} = Notifications.create_task_reminder(todo, 2880)
      assert notification3.body =~ "2日"
    end
  end

end