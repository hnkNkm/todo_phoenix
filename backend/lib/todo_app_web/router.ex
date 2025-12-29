defmodule TodoAppWeb.Router do
  use TodoAppWeb, :router

  import TodoAppWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {TodoAppWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_scope_for_user
  end

  pipeline :api do
    plug CORSPlug, origin: ["http://localhost:5173", "http://localhost:3000"]
    plug :accepts, ["json"]
  end

  pipeline :api_auth do
    plug :fetch_api_user
  end

  scope "/", TodoAppWeb do
    pipe_through :browser

    live "/", HomeLive, :index
  end
  
  scope "/", TodoAppWeb do
    pipe_through [:browser, :require_authenticated_user]
    
    # Password setup route (doesn't require password to be set)
    get "/users/setup-password", UserPasswordSetupController, :new
    post "/users/setup-password", UserPasswordSetupController, :create
  end
  
  scope "/", TodoAppWeb do
    pipe_through [:browser, :require_authenticated_user, :require_password_set]
    
    live "/todos", TodoLive, :index
    live "/calendar", CalendarLive, :index
    live "/tags", TagLive, :index
    
  end

  # API routes
  scope "/api", TodoAppWeb.Api do
    pipe_through :api

    # Public auth routes
    post "/auth/register", AuthController, :register
    post "/auth/login", AuthController, :login
  end

  scope "/api", TodoAppWeb.Api do
    pipe_through [:api, :api_auth]

    # Protected auth routes
    get "/auth/me", AuthController, :me
    delete "/auth/logout", AuthController, :logout

    # Todo routes
    resources "/todos", TodoController, except: [:new, :edit]

    # Tag routes
    resources "/tags", TagController, except: [:new, :edit]
  end

  # Keep existing notification routes
  scope "/api", TodoAppWeb do
    pipe_through [:api, :api_auth]

    get "/notifications", NotificationController, :index
    post "/notifications/:id/read", NotificationController, :mark_as_read
    post "/notifications/read-all", NotificationController, :mark_all_as_read
    delete "/notifications/:id", NotificationController, :delete
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:todo_app, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: TodoAppWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", TodoAppWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    get "/users/register", UserRegistrationController, :new
    post "/users/register", UserRegistrationController, :create
  end

  scope "/", TodoAppWeb do
    pipe_through [:browser, :require_authenticated_user]

    get "/users/settings", UserSettingsController, :edit
    put "/users/settings", UserSettingsController, :update
    get "/users/settings/confirm-email/:token", UserSettingsController, :confirm_email
  end

  scope "/", TodoAppWeb do
    pipe_through [:browser]

    get "/users/log-in", UserSessionController, :new
    get "/users/log-in/:token", UserSessionController, :confirm
    post "/users/log-in", UserSessionController, :create
    delete "/users/log-out", UserSessionController, :delete
  end
end
