defmodule TodoAppWeb.TagLive do
  use TodoAppWeb, :live_view
  alias TodoApp.Tags
  alias TodoApp.Tags.Tag
  alias TodoApp.Accounts

  @impl true
  def mount(_params, session, socket) do
    current_user = 
      case session["user_token"] && Accounts.get_user_by_session_token(session["user_token"]) do
        {user, _token_inserted_at} -> user
        nil -> nil
      end
    
    {:ok, 
     socket
     |> assign(:current_user, current_user)
     |> assign(:tags, if(current_user, do: Tags.list_user_tags(current_user.id), else: []))
     |> assign(:form, to_form(Tags.change_tag(%Tag{})))
     |> assign(:editing_tag, nil)}
  end

  @impl true
  def handle_event("create_tag", %{"tag" => tag_params}, socket) do
    tag_params = Map.put(tag_params, "user_id", socket.assigns.current_user.id)
    
    case Tags.create_tag(tag_params) do
      {:ok, _tag} ->
        {:noreply,
         socket
         |> assign(:tags, Tags.list_user_tags(socket.assigns.current_user.id))
         |> assign(:form, to_form(Tags.change_tag(%Tag{})))
         |> put_flash(:info, "タグを作成しました")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  @impl true
  def handle_event("edit_tag", %{"id" => id}, socket) do
    tag = Tags.get_user_tag!(socket.assigns.current_user.id, id)
    {:noreply,
     socket
     |> assign(:editing_tag, tag)
     |> assign(:form, to_form(Tags.change_tag(tag)))}
  end

  @impl true
  def handle_event("update_tag", %{"tag" => tag_params}, socket) do
    case Tags.update_tag(socket.assigns.editing_tag, tag_params) do
      {:ok, _tag} ->
        {:noreply,
         socket
         |> assign(:tags, Tags.list_user_tags(socket.assigns.current_user.id))
         |> assign(:editing_tag, nil)
         |> assign(:form, to_form(Tags.change_tag(%Tag{})))
         |> put_flash(:info, "タグを更新しました")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  @impl true
  def handle_event("cancel_edit", _params, socket) do
    {:noreply,
     socket
     |> assign(:editing_tag, nil)
     |> assign(:form, to_form(Tags.change_tag(%Tag{})))}
  end

  @impl true
  def handle_event("delete_tag", %{"id" => id}, socket) do
    tag = Tags.get_user_tag!(socket.assigns.current_user.id, id)
    {:ok, _} = Tags.delete_tag(tag)
    
    {:noreply,
     socket
     |> assign(:tags, Tags.list_user_tags(socket.assigns.current_user.id))
     |> put_flash(:info, "タグを削除しました")}
  end
end