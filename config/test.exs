import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :live_broadcaster, LiveBroadcasterWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "F6iD9xfn/FMIy9SOyR3s88ZrEnP/efFrZc6hLc8biSnTdCFzhXe2DIYuJa0OOkXQ",
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
