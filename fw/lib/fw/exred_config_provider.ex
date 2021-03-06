defmodule Fw.ExredConfigProvider do
  @moduledoc false

  def init_db do
    source = "/var/exred_data/exred.sqlite3"
    dest = "/root/data/exred.sqlite3"

    case File.mkdir_p("/root/data") do
      :ok ->
        copy_db(source, dest)

      {:error, :eexist} ->
        copy_db(source, dest)

      {:error, error} ->
        info("couldn't create data dir (/root/data): #{error}")
    end

    :ok
  end

  defp copy_db(source, dest) do
    case File.cp(source, dest, fn _, _ -> false end) do
      :ok ->
        info("database ready")

      {:error, error} ->
        info("couldn't copy default database cp #{source} -> #{dest}: #{error}")
    end
  end

  def init_wlan(path: wlan_config_path) do
    info("running wlan config provider")
    info("reading wlan config: #{inspect(wlan_config_path)}")

    case YamlElixir.read_from_file(wlan_config_path) do
      {:ok, content} ->
        if Map.has_key?(content, "nerves_network_ssid") and
             Map.has_key?(content, "nerves_network_psk") do
          info("found ssid and psk in wlan config")

          default = [
            wlan0: [
              ssid: "",
              psk: "",
              key_mgmt: :"WPA-PSK"
            ],
            eth0: [
              ipv4_address_method: :dhcp
            ]
          ]

          conf =
            default
            |> put_in([:wlan0, :ssid], content["nerves_network_ssid"])
            |> put_in([:wlan0, :psk], content["nerves_network_psk"])

          Application.put_env(:nerves_network, :default, conf, persistent: true)
          info("created default nerves_network config")
        else
          info(
            "#{inspect(wlan_config_path)} is missing a key (required keys: :nerves_network_ssid, nerves_network_psk)"
          )
        end

      {:error, error} ->
        info("failed to read wlan config file #{inspect(wlan_config_path)}: #{inspect(error)}")
    end

    :ok
  end

  @doc """
  Create the wlan config file.
  Path needs to match the path provided to Fw.WlanConfigProvider in shoehorn config (defaults to /root/wlan_config.yaml)
  """
  def create_config(ssid, psk, path \\ "/root/wlan_config.yaml") do
    content = "nerves_network_ssid: #{ssid}\nnerves_network_psk: #{psk}"
    File.write(path, content)
  end

  defp info(msg) when is_binary(msg) do
    IO.puts("==> #{__MODULE__}: #{msg}")
  end

  defp info(msg) do
    IO.puts("==> #{__MODULE__}: #{inspect(msg)}")
  end
end
