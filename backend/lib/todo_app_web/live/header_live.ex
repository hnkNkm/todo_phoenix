defmodule TodoAppWeb.HeaderLive do
  use TodoAppWeb, :live_component
  alias TodoApp.Notifications

  @impl true
  def update(assigns, socket) do
    socket = 
      socket
      |> assign(assigns)
      |> assign_new(:show_dropdown, fn -> false end)
      |> assign_new(:notifications, fn -> [] end)
      |> assign_new(:unread_count, fn -> 0 end)
      |> assign_new(:subscribed, fn -> false end)
    
    # Only load notifications once on mount
    socket = 
      if connected?(socket) && assigns.current_user && !socket.assigns.subscribed do
        socket
        |> assign(:subscribed, true)
        |> load_notifications()
      else
        socket
      end
    
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <header class="navbar bg-base-200 border-b border-base-300">
      <div class="navbar-start">
        <.link navigate="/" class="btn btn-ghost text-xl">
          <svg viewBox="0 0 20 20" class="h-5 w-5" fill="currentColor">
            <path d="M9 2a1 1 0 000 2h2a1 1 0 100-2H9z" />
            <path fill-rule="evenodd" d="M4 5a2 2 0 012-2 1 1 0 000 2H6a2 2 0 100 4h2a2 2 0 100-4h2a1 1 0 100-2 2 2 0 00-2 2v9a2 2 0 01-2 2H6a2 2 0 01-2-2V5z" clip-rule="evenodd" />
          </svg>
          TodoApp
        </.link>
      </div>
      
      <div class="navbar-center hidden lg:flex">
        <%= if @current_user do %>
          <ul class="menu menu-horizontal px-1">
            <li><.link navigate="/todos" class="btn btn-ghost">タスク</.link></li>
            <li><.link navigate="/calendar" class="btn btn-ghost">カレンダー</.link></li>
            <li><.link navigate="/tags" class="btn btn-ghost">タグ</.link></li>
            <li><a href="#" class="btn btn-ghost">プロジェクト</a></li>
            <li><a href="#" class="btn btn-ghost">レポート</a></li>
          </ul>
        <% end %>
      </div>
      
      <div class="navbar-end">
        <%= if @current_user do %>
          <!-- Notification Bell -->
          <div class="dropdown dropdown-end">
            <button 
              class="btn btn-ghost btn-circle" 
              tabindex="0"
              phx-click="toggle_dropdown"
              phx-target={@myself}
            >
              <div class="indicator">
                <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9" />
                </svg>
                <%= if @unread_count > 0 do %>
                  <span class="badge badge-error badge-xs indicator-item">
                    <%= if @unread_count > 9, do: "9+", else: @unread_count %>
                  </span>
                <% end %>
              </div>
            </button>
            
            <div 
              tabindex="0" 
              class={"dropdown-content z-[1] card card-compact w-80 p-2 shadow-xl bg-base-100 #{unless @show_dropdown, do: "hidden"}"}
            >
              <div class="card-body">
                <div class="flex justify-between items-center border-b pb-2">
                  <h3 class="font-bold">通知</h3>
                  <button 
                    class="btn btn-ghost btn-xs" 
                    phx-click="mark_all_read"
                    phx-target={@myself}
                  >
                    すべて既読
                  </button>
                </div>
                <div class="max-h-96 overflow-y-auto">
                  <%= if @notifications == [] do %>
                    <div class="text-center py-4 text-base-content/60">
                      通知はありません
                    </div>
                  <% else %>
                    <%= for notification <- @notifications do %>
                      <div 
                        class={"p-3 hover:bg-base-200 rounded-lg cursor-pointer #{unless notification.read_at, do: "bg-primary/5"}"}
                        phx-click="mark_read"
                        phx-target={@myself}
                        phx-value-id={notification.id}
                      >
                        <div class="flex justify-between items-start">
                          <div class="flex-1">
                            <p class="font-semibold text-sm"><%= notification.title %></p>
                            <%= if notification.body do %>
                              <p class="text-xs text-base-content/60 mt-1"><%= notification.body %></p>
                            <% end %>
                            <p class="text-xs text-base-content/40 mt-1">
                              <%= format_time(notification.inserted_at) %>
                            </p>
                          </div>
                          <button 
                            class="btn btn-ghost btn-xs" 
                            phx-click="delete_notification"
                            phx-target={@myself}
                            phx-value-id={notification.id}
                          >
                            ×
                          </button>
                        </div>
                      </div>
                    <% end %>
                  <% end %>
                </div>
              </div>
            </div>
          </div>
          
          <!-- User Menu -->
          <div class="dropdown dropdown-end">
            <label tabindex="0" class="btn btn-ghost btn-circle avatar">
              <div class="w-10 rounded-full bg-primary text-primary-content flex items-center justify-center">
                <span class="text-lg font-semibold">
                  <%= String.first(@current_user.email) |> String.upcase() %>
                </span>
              </div>
            </label>
            <ul tabindex="0" class="mt-3 z-[1] p-2 shadow menu menu-sm dropdown-content bg-base-200 rounded-box w-52">
              <li class="menu-title">
                <span><%= @current_user.email %></span>
              </li>
              <li>
                <.link navigate="/users/settings">
                  <svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z" />
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                  </svg>
                  設定
                </.link>
              </li>
              <li>
                <.link href={~p"/users/log-out"} method="delete">
                  <svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1" />
                  </svg>
                  ログアウト
                </.link>
              </li>
            </ul>
          </div>
        <% else %>
          <div class="flex items-center gap-2">
            <.link navigate="/users/log-in" class="btn btn-ghost">ログイン</.link>
            <.link navigate="/users/register" class="btn btn-primary">新規登録</.link>
          </div>
        <% end %>
      </div>
    </header>
    """
  end

  @impl true
  def handle_event("toggle_dropdown", _params, socket) do
    new_state = !socket.assigns.show_dropdown
    
    socket = 
      if new_state do
        load_notifications(socket)
      else
        socket
      end
    
    {:noreply, assign(socket, :show_dropdown, new_state)}
  end

  @impl true
  def handle_event("mark_read", %{"id" => id}, socket) do
    if user = socket.assigns.current_user do
      notification = Notifications.get_notification!(id, user.id)
      {:ok, _} = Notifications.mark_as_read(notification)
      
      {:noreply, load_notifications(socket)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("mark_all_read", _params, socket) do
    if user = socket.assigns.current_user do
      Notifications.mark_all_as_read(user.id)
      {:noreply, load_notifications(socket)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("delete_notification", %{"id" => id}, socket) do
    if user = socket.assigns.current_user do
      notification = Notifications.get_notification!(id, user.id)
      {:ok, _} = Notifications.delete_notification(notification)
      
      {:noreply, load_notifications(socket)}
    else
      {:noreply, socket}
    end
  end

  defp load_notifications(socket) do
    if user = socket.assigns.current_user do
      notifications = Notifications.list_user_notifications(user.id, limit: 10)
      unread_count = Notifications.unread_count(user.id)
      
      socket
      |> assign(:notifications, notifications)
      |> assign(:unread_count, unread_count)
    else
      socket
    end
  end

  defp format_time(datetime) do
    now = DateTime.utc_now()
    diff = DateTime.diff(now, datetime, :second)
    
    cond do
      diff < 60 -> "たった今"
      diff < 3600 -> "#{div(diff, 60)}分前"
      diff < 86400 -> "#{div(diff, 3600)}時間前"
      true -> "#{div(diff, 86400)}日前"
    end
  end
end