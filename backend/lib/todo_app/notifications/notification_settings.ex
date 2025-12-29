defmodule TodoApp.Notifications.NotificationSettings do
  use Ecto.Schema
  import Ecto.Changeset

  schema "notification_settings" do
    field :browser_enabled, :boolean, default: true
    field :email_enabled, :boolean, default: false
    field :reminder_minutes_before, {:array, :integer}, default: [60, 1440]
    field :quiet_hours_start, :time
    field :quiet_hours_end, :time
    field :enabled_days, {:array, :integer}, default: [0, 1, 2, 3, 4, 5, 6]

    belongs_to :user, TodoApp.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(settings, attrs) do
    settings
    |> cast(attrs, [
      :browser_enabled,
      :email_enabled,
      :reminder_minutes_before,
      :quiet_hours_start,
      :quiet_hours_end,
      :enabled_days,
      :user_id
    ])
    |> validate_required([:user_id])
    |> validate_reminder_times()
    |> validate_enabled_days()
    |> foreign_key_constraint(:user_id)
    |> unique_constraint(:user_id)
  end

  defp validate_reminder_times(changeset) do
    validate_change(changeset, :reminder_minutes_before, fn :reminder_minutes_before, times ->
      if Enum.all?(times, &(&1 > 0 and &1 < 10080)) do # Max 1 week
        []
      else
        [reminder_minutes_before: "リマインダー時間は1分から1週間の間で設定してください"]
      end
    end)
  end

  defp validate_enabled_days(changeset) do
    validate_change(changeset, :enabled_days, fn :enabled_days, days ->
      if Enum.all?(days, &(&1 >= 0 and &1 <= 6)) do
        []
      else
        [enabled_days: "曜日は0（日曜）から6（土曜）の値で指定してください"]
      end
    end)
  end
end