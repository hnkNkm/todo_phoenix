# Script to update existing todos with today's date
alias TodoApp.Repo
alias TodoApp.Todos
alias TodoApp.Accounts

# すべてのユーザーを取得
users = Repo.all(Accounts.User)

today = Date.utc_today()

Enum.each(users, fn user ->
  todos = Todos.list_user_todos(user.id)
  
  Enum.each(todos, fn todo ->
    if is_nil(todo.due_date) do
      case Todos.update_todo(todo, %{due_date: today}) do
        {:ok, updated_todo} ->
          IO.puts("Updated todo '#{updated_todo.title}' with due date #{today}")
        {:error, changeset} ->
          IO.puts("Failed to update todo '#{todo.title}': #{inspect(changeset.errors)}")
      end
    end
  end)
end)

IO.puts("\nAll existing todos without due dates have been updated with today's date: #{today}")