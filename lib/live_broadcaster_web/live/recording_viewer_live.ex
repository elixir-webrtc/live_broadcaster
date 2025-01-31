defmodule LiveBroadcasterWeb.RecordingViewerLive do
  use LiveBroadcasterWeb, :live_view

  require Logger

  alias LiveExWebRTC.Player.Element

  @impl true
  def render(assigns) do
    ~H"""
    <Element.live_render socket={@socket} player_elem={@player_elem} />
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    socket =
      Element.attach(socket,
        id: "player-elem",
        source: "https://fly.storage.tigris.dev/gregorsamsa/publisher_nil.webm"
      )

    {:ok, socket}
  end
end
