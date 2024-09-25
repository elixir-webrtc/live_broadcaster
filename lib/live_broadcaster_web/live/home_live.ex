defmodule LiveBroadcasterWeb.HomeLive do
  use LiveBroadcasterWeb, :live_view

  require Logger

  alias Phoenix.PubSub
  alias ExWebRTC.PeerConnection
  alias ExRTCP.Packet.PayloadFeedback.PLI

  @impl true
  def render(assigns) do
    ~H"""
    <.live_component
      module={LiveExWebRTC.Subscriber}
      id="subscriber"
      ice_servers={[%{urls: "stun:stun.l.google.com:19302"}]}
      ice_ip_filter={Application.get_env(:live_broadcaster, :ice_ip_filter)}
    />
    """
  end

  @impl true
  def handle_info({:live_ex_webrtc, info}, socket) do
    socket =
      assign(socket,
        pc: info.pc,
        audio_track_id: info.audio_track_id,
        video_track_id: info.video_track_id
      )

    {:noreply, socket}
  end

  @impl true
  def handle_info({:ex_webrtc, _pid, {:connection_state_change, :connected}}, socket) do
    PubSub.subscribe(LiveBroadcaster.PubSub, "audio")
    PubSub.subscribe(LiveBroadcaster.PubSub, "video")
    PubSub.broadcast(LiveBroadcaster.PubSub, "publisher", :keyframe_request)
    {:noreply, socket}
  end

  @impl true
  def handle_info({:ex_webrtc, _pc, {:rtcp, packets}}, state) do
    # Browser, we are sending to, requested a keyframe.
    # Forward this request to the publisher.
    if Enum.any?(packets, fn {_, packet} -> match?(%PLI{}, packet) end) do
      PubSub.broadcast(LiveBroadcaster.PubSub, "publisher", :keyframe_request)
    end

    {:noreply, state}
  end

  @impl true
  def handle_info({:audio, packet}, socket) do
    PeerConnection.send_rtp(socket.assigns.pc, socket.assigns.audio_track_id, packet)
    {:noreply, socket}
  end

  @impl true
  def handle_info({:video, packet}, socket) do
    PeerConnection.send_rtp(socket.assigns.pc, socket.assigns.video_track_id, packet)
    {:noreply, socket}
  end

  @impl true
  def handle_info(_, socket) do
    {:noreply, socket}
  end
end
