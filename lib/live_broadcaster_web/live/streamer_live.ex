defmodule LiveBroadcasterWeb.StreamerLive do
  use LiveBroadcasterWeb, :live_view

  alias LiveExWebRTC.Publisher

  @impl true
  def mount(_params, _session, socket) do
    socket =
      Publisher.attach(socket,
        id: "publisher",
        pubsub: LiveBroadcaster.PubSub,
        ice_servers: [%{urls: "stun:stun.l.google.com:19302"}],
        ice_ip_filter: Application.get_env(:live_broadcaster, :ice_ip_filter)
      )

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Publisher.live_render socket={@socket} publisher={@publisher} />
    """
  end
end
