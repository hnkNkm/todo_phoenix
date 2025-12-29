defmodule TodoAppWeb.Api.TagController do
  use TodoAppWeb, :controller
  alias TodoApp.Tags
  alias TodoApp.Tags.Tag

  action_fallback TodoAppWeb.FallbackController

  def index(conn, _params) do
    user = conn.assigns.current_user
    tags = Tags.list_user_tags(user.id)
    json(conn, %{data: tags})
  end

  def create(conn, %{"tag" => tag_params}) do
    user = conn.assigns.current_user
    tag_params = Map.put(tag_params, "user_id", user.id)

    case Tags.create_tag(tag_params) do
      {:ok, tag} ->
        conn
        |> put_status(:created)
        |> json(%{data: tag})

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: changeset_errors(changeset)})
    end
  end

  def show(conn, %{"id" => id}) do
    user = conn.assigns.current_user
    tag = Tags.get_user_tag!(user.id, id)
    json(conn, %{data: tag})
  end

  def update(conn, %{"id" => id, "tag" => tag_params}) do
    user = conn.assigns.current_user
    tag = Tags.get_user_tag!(user.id, id)

    case Tags.update_tag(tag, tag_params) do
      {:ok, tag} ->
        json(conn, %{data: tag})

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: changeset_errors(changeset)})
    end
  end

  def delete(conn, %{"id" => id}) do
    user = conn.assigns.current_user
    tag = Tags.get_user_tag!(user.id, id)
    {:ok, _tag} = Tags.delete_tag(tag)

    send_resp(conn, :no_content, "")
  end

  defp changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end