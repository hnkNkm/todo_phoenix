defmodule TodoAppWeb.UserSessionHTML do
  use TodoAppWeb, :html

  embed_templates "user_session_html/*"

  defp local_mail_adapter? do
    Application.get_env(:todo_app, TodoApp.Mailer)[:adapter] == Swoosh.Adapters.Local
  end
end
