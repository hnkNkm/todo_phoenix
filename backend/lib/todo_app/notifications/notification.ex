defmodule TodoApp.Notifications.Notification do
  use Ecto.Schema
  import Ecto.Changeset

  schema "notifications" do
    field :type, :string
    field :title, :string
    field :body, :string
    field :read_at, :utc_datetime
    field :action_url, :string
    field :metadata, :map, default: %{}

    belongs_to :user, TodoApp.Accounts.User
    belongs_to :todo, TodoApp.Todos.Todo

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(notification, attrs) do
    notification
    |> cast(attrs, [:type, :title, :body, :action_url, :metadata, :user_id, :todo_id])
    |> validate_required([:type, :title, :user_id])
    |> validate_inclusion(:type, ~w(task_due task_overdue task_reminder task_created))
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:todo_id)
  end

  def mark_as_read(notification) do
    notification
    |> change(read_at: DateTime.utc_now(:second))
  end
end