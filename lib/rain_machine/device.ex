defmodule RainMachine.Device do
  defstruct name: nil,
            ip_address: nil,
            token: nil,
            zones: nil,
            programs: nil

  require Logger
  
  alias RainMachine.Device
  alias RainMachine.Zone

  def create(ip_address, password) do
    %Device{
      name: "RainMaster",
      ip_address: ip_address
    }
    |> get_token(password)
    |> case do
      {:ok, device} ->
        device = get_zones(device)
        {:ok, device}
      
      {:err, reason} ->
        {:err, reason} |> IO.inspect(label: "rainmaster fail")
    end
  end

  def start_zone(%Device{ip_address: ip_address, token: token}, %{uid: uid} = zone) do
    HTTPoison.post(
      "https://#{ip_address}:8080/api/4/zone/#{uid}/start?access_token=#{token}",
      "{\"time\": 1200}",
      [
        {"Content-Type", "application/json"},
      ],
      get_options()
    )
    |> case do
      {:ok, %HTTPoison.Response{body: body}} ->
        %{"statusCode" => 0, "message" => _message} = Jason.decode!(body)
        {:ok, zone}
      err ->
        {:err, reason: inspect(err)}
      end

  end

  def stop_zone(%Device{ip_address: ip_address, token: token}, %{uid: uid} = zone) do
    HTTPoison.post(
      "https://#{ip_address}:8080/api/4/zone/#{uid}/stop?access_token=#{token}",
      "",
      [
        {"Content-Type", "application/json"},
      ],
      get_options()
    )
    |> case do
      {:ok, %HTTPoison.Response{body: body}} ->
        %{"statusCode" => 0} = Jason.decode!(body)
        {:ok, zone}
      err ->
        {:err, reason: inspect(err)}
      end

  end

  def get_token(%{ip_address: ip_address} = device, password) do
    HTTPoison.post(
      "https://#{ip_address}:8080/api/4/auth/login" |> IO.inspect,
      "{\"pwd\": \"#{password}\", \"remember\": 1}",
      [
        {"Content-Type", "application/json"},
      ],
      get_options()
    )
    |> case do
      {:ok, %HTTPoison.Response{body: body}} ->
        %{"access_token" => token} = Jason.decode!(body)
        {:ok, %{device | token: token}}
      err ->
        {:err, reason: inspect(err)} |> IO.inspect(label: "rainmachine auth error")
      end
  end


  def get_device(device) do
    device
    |> get_zones()
  end

  def get_zones(%{ip_address: ip_address, token: token} = device) do
    %HTTPoison.Response{body: body} =
      HTTPoison.get!(
        "https://#{ip_address}:8080/api/4/zone?access_token=#{token}",
        [
          {"Content-Type", "application/json"},
        ],
        get_options()
      )

    {:ok, %{"zones" => zones}} = Jason.decode(body)

    zones = for %{"active" => true, "name" => name, "uid" => uid, "state" => state} <- zones do
      %Zone{name: name, uid: uid, state: state}
    end
    %{device | zones: zones}
  end

  defp get_options do
    cert_path = Path.join(["#{:code.priv_dir(:rain_machine)}", "certs", "dev.mergebot.com.crt"])
    key_path = Path.join(["#{:code.priv_dir(:rain_machine)}", "certs", "dev.mergebot.com.key"])
    
    [ssl: [certfile: cert_path, keyfile: key_path]]
  end
end
