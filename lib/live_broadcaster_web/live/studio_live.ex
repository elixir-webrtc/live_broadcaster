defmodule LiveBroadcasterWeb.StudioLive do
  use LiveBroadcasterWeb, :live_view

  alias ExWebRTC.PeerConnection
  alias Phoenix.PubSub

  def mount(_params, _session, socket) do
    PubSub.subscribe(LiveBroadcaster.PubSub, "publisher")
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <.live_component
      module={LiveExWebRTC.Publisher}
      id="publisher"
      ice_servers={[%{urls: "stun:stun.l.google.com:19302"}]}
      ice_ip_filter={Application.get_env(:live_broadcaster, :ice_ip_filter)}
    />
    """
  end

  def handle_info({:live_ex_webrtc, info}, socket) do
    socket =
      assign(socket,
        pc: info[:pc],
        audio_track_id: info[:audio_track_id],
        video_track_id: info[:video_track_id]
      )

    {:noreply, socket}
  end

  def handle_info(
        {:ex_webrtc, _pc, {:rtp, track_id, nil, packet}},
        %{assigns: %{video_track_id: track_id}} = socket
      ) do
    PubSub.broadcast(LiveBroadcaster.PubSub, "video", {:video, packet})
    {:noreply, socket}
  end

  def handle_info(
        {:ex_webrtc, _pc, {:rtp, track_id, nil, packet}},
        %{assigns: %{audio_track_id: track_id}} = socket
      ) do
    PubSub.broadcast(LiveBroadcaster.PubSub, "audio", {:audio, packet})
    {:noreply, socket}
  end

  def handle_info(:keyframe_request, %{assigns: %{pc: pc}} = socket) when pc != nil do
    :ok = PeerConnection.send_pli(socket.assigns.pc, socket.assigns.video_track_id)
    {:noreply, socket}
  end

  def handle_info(_msg, socket) do
    {:noreply, socket}
  end
end
