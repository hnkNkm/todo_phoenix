defmodule TodoAppWeb.FallbackController do
  use TodoAppWeb, :controller

  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(:not_found)
    |> put_view(TodoAppWeb.ErrorJSON)
    |> render(:"404")
  end

  def call(conn, {:error, :unauthorized}) do
    conn
    |> put_status(:unauthorized)
    |> put_view(TodoAppWeb.ErrorJSON)
    |> render(:"401")
  end

  def call(conn, {:error, changeset}) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(TodoAppWeb.ErrorJSON)
    |> render(:"422", changeset: changeset)
  end
end