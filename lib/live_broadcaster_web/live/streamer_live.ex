defmodule LiveBroadcasterWeb.StreamerLive do
  use LiveBroadcasterWeb, :live_view

  alias LiveExWebRTC.Publisher

  require Logger

  @video_codecs [
    %ExWebRTC.RTPCodecParameters{
      payload_type: 96,
      mime_type: "video/VP8",
      clock_rate: 90_000
    }
  ]

  @audio_codecs [
    %ExWebRTC.RTPCodecParameters{
      payload_type: 111,
      mime_type: "audio/opus",
      clock_rate: 48_000,
      channels: 2
    }
  ]

  @impl true
  def mount(_params, _session, socket) do
    # to nie powinno być tu tak naprawdę, ale to się potem ustali
    ExWebRTC.Recorder.controlling_process(LiveBroadcaster.Recorder, self())

    socket =
      Publisher.attach(socket,
        id: "publisher",
        pubsub: LiveBroadcaster.PubSub,
        recorder: LiveBroadcaster.Recorder,
        ice_servers: [%{urls: "stun:stun.l.google.com:19302"}],
        ice_ip_filter: Application.get_env(:live_broadcaster, :ice_ip_filter),
        video_codecs: @video_codecs,
        audio_codecs: @audio_codecs
      )

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Publisher.live_render socket={@socket} publisher={@publisher} />
    """
  end

  @impl true
  def handle_info(
        {:ex_webrtc_recorder, _pid, {:upload_complete, _ref, recording_manifest}},
        socket
      ) do
    Logger.info("Recording upload complete")

    base_s3_config = [
      scheme: "https://",
      host: "fly.storage.tigris.dev",
      port: 443,
      access_key_id: "[REDACTED]",
      secret_access_key: "[REDACTED]"
    ]

    fetch_s3_config =
      base_s3_config
      |> Keyword.put(:access_key_id, "[REDACTED]")
      |> Keyword.put(:secret_access_key, "[REDACTED]")
      |> Keyword.put_new(:region, "auto")

    self_pid = self()

    FLAME.cast(LiveBroadcaster.ConverterRunner, fn ->
      Logger.info("Processing recording...")

      convert_result =
        ExWebRTC.Recorder.Converter.convert_manifest!(recording_manifest,
          s3_download_config: base_s3_config,
          s3_upload_config: base_s3_config ++ [bucket_name: "gregorsamsa"]
        )

      Logger.info("Recording processed and uploaded")

      # XXX generowanie urla to nie tu, raczej trzeba przekazac info w inny sposob
      Map.new(convert_result, fn {id, %{location: s3_scheme_url}} ->
        # XXX nie powinienem musieć tego wywoływać...
        {:ok, bucket_name, path} = ExWebRTC.Recorder.S3.Utils.parse_url(s3_scheme_url)
        {:ok, url} = ExAws.S3.presigned_url(Map.new(fetch_s3_config), :get, bucket_name, path)

        {id, url}
      end)
      |> then(&send(self_pid, {:flame_result, &1}))
    end)

    {:noreply, socket}
  end

  @impl true
  def handle_info({:flame_result, url_map}, socket) do
    Logger.info("Received FLAME result")
    url = url_map |> Map.values() |> hd()

    Logger.info("Processed video URL: #{inspect(url)}")

    {:noreply, socket}
  end
end

# what we're gonna wanna need:
#   >miniaturka
#   >tytuł+opis
#   >długość
#   >data (mamy start_time)
#   >liczba wyświetleń
