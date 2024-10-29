defmodule LiveBroadcasterWeb.StreamViewerLive do
  use LiveBroadcasterWeb, :live_view

  require Logger

  alias LiveExWebRTC.Player

  @impl true
  def render(assigns) do
    ~H"""
    <Player.live_render socket={@socket} player={@player} />
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    socket =
      Player.attach(socket,
        id: "player",
        publisher_id: "publisher",
        pubsub: LiveBroadcaster.PubSub,
        ice_servers: [%{urls: "stun:stun.l.google.com:19302"}],
        ice_ip_filter: Application.get_env(:live_broadcaster, :ice_ip_filter)
      )

    {:ok, socket}
  end
end
