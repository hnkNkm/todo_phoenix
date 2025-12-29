defmodule Mix.Tasks.SendNotification do
  use Mix.Task
  alias TodoApp.Notifications

  @shortdoc "Send a custom notification to a user"
  
  @moduledoc """
  Send a custom notification to a user.
  
  Usage:
    mix send_notification --user-id 2 --title "タイトル" --body "本文"
    mix send_notification --user-id 2 --type task_reminder --title "重要なお知らせ" --body "これはテスト通知です" --action-url "/todos"
  """

  def run(args) do
    Mix.Task.run("app.start")
    
    {opts, _, _} = OptionParser.parse(args, 
      strict: [
        user_id: :integer,
        type: :string,
        title: :string,
        body: :string,
        action_url: :string
      ]
    )
    
    user_id = Keyword.get(opts, :user_id, 2)
    type = Keyword.get(opts, :type, "task_reminder")
    title = Keyword.get(opts, :title, "テスト通知")
    body = Keyword.get(opts, :body, "これはテスト通知です")
    action_url = Keyword.get(opts, :action_url)
    
    notification_attrs = %{
      user_id: user_id,
      type: type,
      title: title,
      body: body,
      action_url: action_url
    }
    
    case Notifications.create_notification(notification_attrs) do
      {:ok, notification} ->
        IO.puts("\n✅ 通知を送信しました！")
        IO.puts("━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        IO.puts("📬 タイプ: #{notification.type}")
        IO.puts("📝 タイトル: #{notification.title}")
        IO.puts("📄 本文: #{notification.body || "なし"}")
        IO.puts("👤 ユーザーID: #{notification.user_id}")
        IO.puts("🔗 アクションURL: #{notification.action_url || "なし"}")
        IO.puts("━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        
      {:error, changeset} ->
        IO.puts("\n❌ 通知の送信に失敗しました:")
        Enum.each(changeset.errors, fn {field, {msg, _}} ->
          IO.puts("  - #{field}: #{msg}")
        end)
    end
  end
end

defmodule Mix.Tasks.SendNotification.Interactive do
  use Mix.Task
  alias TodoApp.Notifications

  @shortdoc "Send a notification interactively"
  
  @moduledoc """
  インタラクティブに通知を送信します。
  
  Usage:
    mix send_notification.interactive
  """

  def run(_args) do
    Mix.Task.run("app.start")
    
    IO.puts("\n🔔 通知送信ツール")
    IO.puts("━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    
    user_id = IO.gets("ユーザーID (デフォルト: 2): ") 
              |> String.trim()
              |> parse_integer(2)
    
    IO.puts("\n通知タイプを選択:")
    IO.puts("  1. task_reminder (タスクリマインダー)")
    IO.puts("  2. task_overdue (期限切れ)")
    IO.puts("  3. task_created (タスク作成)")
    IO.puts("  4. task_due (期限通知)")
    
    type = IO.gets("番号を選択 (デフォルト: 1): ")
           |> String.trim()
           |> parse_type()
    
    title = IO.gets("\nタイトル: ") |> String.trim()
    body = IO.gets("本文 (任意): ") |> String.trim()
    action_url = IO.gets("アクションURL (任意): ") |> String.trim()
    
    notification_attrs = %{
      user_id: user_id,
      type: type,
      title: if(title == "", do: "テスト通知", else: title),
      body: if(body == "", do: nil, else: body),
      action_url: if(action_url == "", do: nil, else: action_url)
    }
    
    case Notifications.create_notification(notification_attrs) do
      {:ok, notification} ->
        IO.puts("\n✅ 通知を送信しました！")
        IO.puts("━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        IO.puts("📬 タイプ: #{notification.type}")
        IO.puts("📝 タイトル: #{notification.title}")
        IO.puts("📄 本文: #{notification.body || "なし"}")
        IO.puts("👤 ユーザーID: #{notification.user_id}")
        IO.puts("🔗 アクションURL: #{notification.action_url || "なし"}")
        IO.puts("━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        
        if IO.gets("\n別の通知を送信しますか？ (y/n): ") |> String.trim() |> String.downcase() == "y" do
          run([])
        end
        
      {:error, changeset} ->
        IO.puts("\n❌ 通知の送信に失敗しました:")
        Enum.each(changeset.errors, fn {field, {msg, _}} ->
          IO.puts("  - #{field}: #{msg}")
        end)
    end
  end
  
  defp parse_integer("", default), do: default
  defp parse_integer(str, default) do
    case Integer.parse(str) do
      {num, _} -> num
      :error -> default
    end
  end
  
  defp parse_type("2"), do: "task_overdue"
  defp parse_type("3"), do: "task_created"
  defp parse_type("4"), do: "task_due"
  defp parse_type(_), do: "task_reminder"
end