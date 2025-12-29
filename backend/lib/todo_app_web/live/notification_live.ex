defmodule TodoAppWeb.NotificationLive do
  use TodoAppWeb, :live_view
  alias TodoApp.Notifications
  
  @impl true
  def render(assigns) do
    ~H"""
    <div class="dropdown dropdown-end" id="notification-dropdown">
      <button class="btn btn-ghost btn-circle" tabindex="0" phx-click="toggle_dropdown">
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
        class={"dropdown-content z-[1] card card-compact w-80 p-2 shadow-xl bg-base-100 #{if @show_dropdown, do: "", else: "hidden"}"}
      >
        <div class="card-body">
          <div class="flex justify-between items-center border-b pb-2">
            <h3 class="font-bold">通知</h3>
            <button class="btn btn-ghost btn-xs" phx-click="mark_all_read">すべて既読</button>
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
    """
  end
  
  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) && socket.assigns[:current_user] do
      Notifications.subscribe(socket.assigns.current_user.id)
      Process.send_after(self(), :load_notifications, 100)
    end
    
    {:ok,
     socket
     |> assign(:notifications, [])
     |> assign(:unread_count, 0)
     |> assign(:show_dropdown, false)}
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
    if user = socket.assigns[:current_user] do
      notification = Notifications.get_notification!(id, user.id)
      {:ok, _} = Notifications.mark_as_read(notification)
      
      {:noreply, load_notifications(socket)}
    else
      {:noreply, socket}
    end
  end
  
  @impl true
  def handle_event("mark_all_read", _params, socket) do
    if user = socket.assigns[:current_user] do
      Notifications.mark_all_as_read(user.id)
      {:noreply, load_notifications(socket)}
    else
      {:noreply, socket}
    end
  end
  
  @impl true
  def handle_event("delete_notification", %{"id" => id}, socket) do
    if user = socket.assigns[:current_user] do
      notification = Notifications.get_notification!(id, user.id)
      {:ok, _} = Notifications.delete_notification(notification)
      
      {:noreply, load_notifications(socket)}
    else
      {:noreply, socket}
    end
  end
  
  @impl true
  def handle_info(:load_notifications, socket) do
    {:noreply, load_notifications(socket)}
  end
  
  @impl true
  def handle_info({:notification_created, _notification}, socket) do
    {:noreply, load_notifications(socket)}
  end
  
  defp load_notifications(socket) do
    if user = socket.assigns[:current_user] do
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