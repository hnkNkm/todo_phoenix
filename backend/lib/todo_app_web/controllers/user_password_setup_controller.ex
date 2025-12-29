defmodule TodoAppWeb.UserPasswordSetupController do
  use TodoAppWeb, :controller

  alias TodoApp.Accounts

  def new(conn, _params) do
    user = conn.assigns.current_scope.user
    
    # If user already has a password, redirect to home
    if user.hashed_password do
      redirect(conn, to: ~p"/")
    else
      changeset = Accounts.change_user_password(user)
      render(conn, :new, changeset: changeset)
    end
  end

  def create(conn, %{"user" => password_params}) do
    user = conn.assigns.current_scope.user
    
    case Accounts.update_user_password(user, password_params) do
      {:ok, {updated_user, _tokens}} ->
        conn
        |> put_flash(:info, "パスワードが設定されました。")
        |> TodoAppWeb.UserAuth.log_in_user(updated_user)
        
      {:error, changeset} ->
        render(conn, :new, changeset: changeset)
    end
  end
end