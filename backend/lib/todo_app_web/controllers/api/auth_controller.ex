defmodule TodoAppWeb.Api.AuthController do
  use TodoAppWeb, :controller
  alias TodoApp.Accounts
  alias TodoApp.Accounts.User

  action_fallback TodoAppWeb.FallbackController

  def register(conn, %{"user" => user_params}) do
    case Accounts.register_user(user_params) do
      {:ok, user} ->
        token = Accounts.generate_user_session_token(user)
        
        conn
        |> put_status(:created)
        |> json(%{
          data: %{
            user: %{
              id: user.id,
              email: user.email,
              inserted_at: user.inserted_at
            },
            token: token
          }
        })

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: changeset_errors(changeset)})
    end
  end

  def login(conn, %{"email" => email, "password" => password}) do
    if user = Accounts.get_user_by_email_and_password(email, password) do
      token = Accounts.generate_user_session_token(user)
      
      json(conn, %{
        data: %{
          user: %{
            id: user.id,
            email: user.email,
            inserted_at: user.inserted_at
          },
          token: token
        }
      })
    else
      conn
      |> put_status(:unauthorized)
      |> json(%{errors: %{detail: "Invalid email or password"}})
    end
  end

  def me(conn, _params) do
    user = conn.assigns.current_user
    
    json(conn, %{
      data: %{
        id: user.id,
        email: user.email,
        inserted_at: user.inserted_at
      }
    })
  end

  def logout(conn, _params) do
    token = get_req_header(conn, "authorization")
            |> List.first()
            |> String.replace("Bearer ", "")
    
    Accounts.delete_user_session_token(token)
    
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