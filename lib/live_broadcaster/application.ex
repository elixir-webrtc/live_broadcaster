defmodule LiveBroadcaster.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children =
      case FLAME.Parent.get() do
        %FLAME.Parent{} ->
          []

        nil ->
          [
            LiveBroadcasterWeb.Telemetry,
            {DNSCluster,
             query: Application.get_env(:live_broadcaster, :dns_cluster_query) || :ignore},
            {Phoenix.PubSub, name: LiveBroadcaster.PubSub},
            {ExWebRTC.Recorder,
             [
               # XXX SECRITISE
               [
                 base_dir: "./recordings",
                 on_start: nil,
                 s3_config: [
                   bucket_name: "gregorsamsa-rtpx",
                   scheme: "https://",
                   host: "fly.storage.tigris.dev",
                   port: 443,
                   access_key_id: "[REDACTED]",
                   secret_access_key: "[REDACTED]"
                 ]
               ],
               [name: LiveBroadcaster.Recorder]
             ]},
            {FLAME.Pool,
             name: LiveBroadcaster.ConverterRunner,
             min: 0,
             max: 10,
             max_concurrency: 5,
             idle_shutdown_after: 30_000},
            LiveBroadcasterWeb.Endpoint
          ]
      end

    opts = [strategy: :one_for_one, name: LiveBroadcaster.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    LiveBroadcasterWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
