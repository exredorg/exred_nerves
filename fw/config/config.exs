# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# Customize non-Elixir parts of the firmware. See
# https://hexdocs.pm/nerves/advanced-configuration.html for details.

config :nerves, :firmware, rootfs_overlay: "rootfs_overlay"

# Use shoehorn to start the main application. See the shoehorn
# docs for separating out critical OTP applications such as those
# involved with firmware updates.

config :shoehorn,
  init: [:nerves_runtime, :nerves_init_gadget, :nerves_network],
  app: Mix.Project.config()[:app]

config :nerves_network,
  regulatory_domain: "US"

key_mgmt = System.get_env("NERVES_NETWORK_KEY_MGMT") || "WPA-PSK"

config :nerves_network, :default,
  wlan0: [
    ssid: System.get_env("NERVES_NETWORK_SSID"),
    psk: System.get_env("NERVES_NETWORK_PSK"),
    key_mgmt: String.to_atom(key_mgmt)
  ],
  eth0: [
    ipv4_address_method: :dhcp
  ]

# Use Ringlogger as the logger backend and remove :console.
# See https://hexdocs.pm/ring_logger/readme.html for more information on
# configuring ring_logger.

config :logger, backends: [RingLogger]

# Authorize the device to receive firmware using your public key.
# See https://hexdocs.pm/nerves_firmware_ssh/readme.html for more information
# on configuring nerves_firmware_ssh.

keys =
  [
    Path.join([System.user_home!(), ".ssh", "id_rsa.pub"]),
    Path.join([System.user_home!(), ".ssh", "id_ecdsa.pub"]),
    Path.join([System.user_home!(), ".ssh", "id_ed25519.pub"])
  ]
  |> Enum.filter(&File.exists?/1)

if keys == [],
  do:
    Mix.raise("""
    No SSH public keys found in ~/.ssh. An ssh authorized key is needed to
    log into the Nerves device and update firmware on it using ssh.
    See your project's config.exs for this error message.
    """)

config :nerves_firmware_ssh,
  authorized_keys: Enum.map(keys, &File.read!/1)

# Configure nerves_init_gadget.
# See https://hexdocs.pm/nerves_init_gadget/readme.html for more information.

# Setting the node_name will enable Erlang Distribution.
# Only enable this for prod if you understand the risks.
node_name = if Mix.env() != :prod, do: "fw"

config :nerves_init_gadget,
  ifname: "usb0",
  address_method: :dhcpd,
  mdns_domain: "nerves.local",
  node_name: node_name,
  node_host: :mdns_domain

# --- BEGIN exred_ui config --------------------------------------------------
config :exred_ui, ExredUIWeb.Endpoint,
  load_from_system_env: false,
  http: [port: 8080],
  url: [host: "localhost", port: 8080],
  cache_static_manifest: "priv/static/cache_manifest.json",
  server: true,
  check_origin: false,
  root: ".",
  version: Application.spec(:exred_ui, :vsn),
  secret_key_base: "lNynDH9TigJu4E18vTfeAXKJUU6Vx8ARmpuFUW3DXOTdGiKSKktPPswoWAhx9LwW",
  render_errors: [view: ExredUIWeb.ErrorView, accepts: ~w(json json-api)],
  pubsub: [name: ExredUI.PubSub, adapter: Phoenix.PubSub.PG2]

config :phoenix, :format_encoders, "json-api": Poison

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :mime, :types, %{
  "application/vnd.api+json" => ["json-api"]
}

config :guardian, Guardian,
  # optional
  allowed_algos: ["HS512"],
  # optional
  verify_module: Guardian.JWT,
  issuer: "Pchat",
  ttl: {30, :days},
  # optional
  verify_issuer: true,
  secret_key:
    System.get_env("GUARDIAN_SECRET") ||
      "VR8YBJA94hYgn5KSxAHhr6RtBNJI2ZIdt11Cl3WlaxNtC+lX3hPTVSbFOBDKPEGF",
  serializer: Pchat.GuardianSerializer

config :exred_ui,
  ecto_repos: [ExredUI.SqliteRepo]

config :exred_ui, ExredUI.SqliteRepo,
  adapter: Sqlite.Ecto2,
  database: "/root/data/exred.sqlite3"

config :exred_ui, ExredUI.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "exred_user",
  password: "hello",
  database: "exred_ui_dev",
  hostname: "localhost",
  port: 5432,
  pool_size: 10

# --- END exred_ui config -----------------------------------------------------

# --- BEGIN exred_scheduler config --------------------------------------------
config :exred_scheduler, :exred_ui_hostname, "localhost"
config :exred_scheduler, :exred_ui_port, 8080

config :logger, :console,
  format: "[$level] $metadata$message\n",
  metadata: [:module, :function]

config :exred_library,
  ecto_repos: [Exred.Library.SqliteRepo]

config :exred_library, Exred.Library.SqliteRepo,
  adapter: Sqlite.Ecto2,
  database: "/root/data/exred.sqlite3"

config :grpc, start_server: true

config :exred_node_aws_iot_daemon, :ssl,
  keyfile: "/var/exred_data/private.pem.key",
  certfile: "/var/exred_data/certificate.pem.crt",
  cacertfile: "/var/exred_data/ca_root.pem"

# --- END exred_scheduler config ----------------------------------------------

# Import target specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
# Uncomment to use target specific configurations

# import_config "#{Mix.target()}.exs"
