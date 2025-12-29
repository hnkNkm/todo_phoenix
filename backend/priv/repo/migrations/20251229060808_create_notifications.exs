defmodule TodoApp.Repo.Migrations.CreateNotifications do
  use Ecto.Migration

  def change do
    create table(:notifications) do
      add :type, :string, null: false
      add :title, :string, null: false
      add :body, :text
      add :read_at, :utc_datetime
      add :action_url, :string
      add :metadata, :map, default: %{}
      
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :todo_id, references(:todos, on_delete: :nilify_all)
      
      timestamps(type: :utc_datetime)
    end

    create index(:notifications, [:user_id])
    create index(:notifications, [:todo_id])
    create index(:notifications, [:read_at])
    create index(:notifications, [:type])
    create index(:notifications, [:inserted_at])

    # 通知設定テーブル
    create table(:notification_settings) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      
      # 通知タイプごとの設定
      add :browser_enabled, :boolean, default: true
      add :email_enabled, :boolean, default: false
      
      # 通知タイミング設定（分単位）
      add :reminder_minutes_before, {:array, :integer}, default: [60, 1440] # 1時間前、1日前
      
      # 通知する時間帯
      add :quiet_hours_start, :time
      add :quiet_hours_end, :time
      
      # 通知する曜日（0=日曜日、6=土曜日）
      add :enabled_days, {:array, :integer}, default: [0, 1, 2, 3, 4, 5, 6]
      
      timestamps(type: :utc_datetime)
    end

    create unique_index(:notification_settings, [:user_id])

    # Push通知購読情報
    create table(:push_subscriptions) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :endpoint, :text, null: false
      add :p256dh_key, :text, null: false
      add :auth_key, :text, null: false
      add :user_agent, :string
      
      timestamps(type: :utc_datetime)
    end

    create index(:push_subscriptions, [:user_id])
    create unique_index(:push_subscriptions, [:endpoint])
  end
end