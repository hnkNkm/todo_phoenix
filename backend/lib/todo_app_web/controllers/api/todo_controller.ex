defmodule TodoAppWeb.Api.TodoController do
  use TodoAppWeb, :controller
  alias TodoApp.Todos
  alias TodoApp.Todos.Todo

  action_fallback TodoAppWeb.FallbackController

  def index(conn, params) do
    user = conn.assigns.current_user
    
    filters = build_filters(params)
    todos = Todos.filter_todos(user.id, filters)
    
    json(conn, %{data: todos})
  end

  def create(conn, %{"todo" => todo_params}) do
    user = conn.assigns.current_user
    todo_params = Map.put(todo_params, "user_id", user.id)

    case Todos.create_todo(todo_params) do
      {:ok, todo} ->
        conn
        |> put_status(:created)
        |> json(%{data: todo})

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: changeset_errors(changeset)})
    end
  end

  def show(conn, %{"id" => id}) do
    user = conn.assigns.current_user
    todo = Todos.get_user_todo!(user.id, id)
    json(conn, %{data: todo})
  end

  def update(conn, %{"id" => id, "todo" => todo_params}) do
    user = conn.assigns.current_user
    todo = Todos.get_user_todo!(user.id, id)

    case Todos.update_todo(todo, todo_params) do
      {:ok, todo} ->
        json(conn, %{data: todo})

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: changeset_errors(changeset)})
    end
  end

  def delete(conn, %{"id" => id}) do
    user = conn.assigns.current_user
    todo = Todos.get_user_todo!(user.id, id)
    {:ok, _todo} = Todos.delete_todo(todo)

    send_resp(conn, :no_content, "")
  end

  defp build_filters(params) do
    filters = []
    
    filters = 
      if params["search"] && params["search"] != "" do
        [{:search, params["search"]} | filters]
      else
        filters
      end
    
    filters = 
      case params["status"] do
        "completed" -> [{:status, "completed"} | filters]
        "incomplete" -> [{:status, "incomplete"} | filters]
        _ -> filters
      end
    
    filters = 
      if params["tag_ids"] && params["tag_ids"] != [] do
        tag_ids = Enum.map(params["tag_ids"], &String.to_integer/1)
        [{:tag_ids, tag_ids} | filters]
      else
        filters
      end
    
    filters = 
      if params["date"] do
        case Date.from_iso8601(params["date"]) do
          {:ok, date} -> [{:date, date} | filters]
          _ -> filters
        end
      else
        filters
      end

    filters
  end

  defp changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end