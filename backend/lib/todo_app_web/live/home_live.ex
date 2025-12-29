defmodule TodoAppWeb.HomeLive do
  use TodoAppWeb, :live_view
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
     |> assign(:page_title, "ホーム")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-base-100">
      <!-- Live Navigation Header -->
      <.live_component
        module={TodoAppWeb.HeaderLive}
        id="header"
        current_user={@current_user}
      />
      
      <!-- Hero Section -->
      <section class="hero min-h-[60vh] bg-gradient-to-br from-primary/10 to-secondary/10">
        <div class="hero-content text-center">
          <div class="max-w-2xl">
            <h1 class="text-5xl font-bold text-base-content mb-8">
              タスク管理を、もっとシンプルに
            </h1>
            <p class="text-xl text-base-content/70 mb-8">
              TodoAppは、あなたの日々のタスクを効率的に管理するためのシンプルで使いやすいツールです。
            </p>
            <%= if @current_user do %>
              <div class="flex gap-4 justify-center">
                <.link navigate={~p"/todos"} class="btn btn-primary btn-lg">
                  タスクを見る
                </.link>
                <.link navigate={~p"/calendar"} class="btn btn-outline btn-lg">
                  カレンダー
                </.link>
              </div>
            <% else %>
              <div class="flex gap-4 justify-center">
                <.link navigate={~p"/users/register"} class="btn btn-primary btn-lg">
                  無料で始める
                </.link>
                <.link navigate={~p"/users/log-in"} class="btn btn-outline btn-lg">
                  ログイン
                </.link>
              </div>
            <% end %>
          </div>
        </div>
      </section>

      <!-- Features Section -->
      <section class="py-16 px-4">
        <div class="max-w-6xl mx-auto">
          <h2 class="text-3xl font-bold text-center mb-12">主な機能</h2>
          <div class="grid grid-cols-1 md:grid-cols-3 gap-8">
            <div class="card bg-base-200">
              <div class="card-body">
                <div class="w-12 h-12 bg-primary rounded-lg flex items-center justify-center mb-4">
                  <svg class="w-6 h-6 text-primary-content" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-6 9l2 2 4-4" />
                  </svg>
                </div>
                <h3 class="card-title">タスク管理</h3>
                <p>期限や優先度を設定して、効率的にタスクを管理できます。</p>
              </div>
            </div>
            
            <div class="card bg-base-200">
              <div class="card-body">
                <div class="w-12 h-12 bg-secondary rounded-lg flex items-center justify-center mb-4">
                  <svg class="w-6 h-6 text-secondary-content" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
                  </svg>
                </div>
                <h3 class="card-title">カレンダービュー</h3>
                <p>カレンダー形式で、一目でタスクの予定を確認できます。</p>
              </div>
            </div>
            
            <div class="card bg-base-200">
              <div class="card-body">
                <div class="w-12 h-12 bg-accent rounded-lg flex items-center justify-center mb-4">
                  <svg class="w-6 h-6 text-accent-content" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 7h.01M7 3h5c.512 0 1.024.195 1.414.586l7 7a2 2 0 010 2.828l-7 7a2 2 0 01-2.828 0l-7-7A1.994 1.994 0 013 12V7a4 4 0 014-4z" />
                  </svg>
                </div>
                <h3 class="card-title">タグ機能</h3>
                <p>タグを使って、タスクを分類・整理できます。</p>
              </div>
            </div>
          </div>
        </div>
      </section>
    </div>
    """
  end
end