defmodule RainMachine.State do
  defmodule Data do
    defstruct devices: %{}, mock_data: false
  end

  use GenServer
  require Logger

  alias RainMachine.Device

  @interval :timer.minutes(1)

  def start_link(_vars) do
    GenServer.start_link(__MODULE__, %Data{}, name: __MODULE__)
  end

  def get_device(ip_address) do
    GenServer.call(__MODULE__, {:get_device, ip_address})
  end

  def add_device(device) do
    GenServer.call(__MODULE__, {:add_device, device}, 90_000)
  end

  def init(data) do
    mock_data = 
      Application.get_env(:rain_machine, Device)
      |> Keyword.get(:mock_data, false)

    data = %{data | mock_data: mock_data}

    Process.send_after(self(), :tick, @interval)
    {:ok, data}
  end

  def handle_info(:tick, %{devices: devices} = state) do
    devices =
      devices
      |> Enum.map(fn {ip_addr, dev} ->
        Process.send(self(), {:broadcast, dev}, [])
        {ip_addr, Device.get_device(dev)}
      end)
      |> Enum.into(%{})

    Process.send_after(self(), :tick, @interval)
    {:noreply, %{state | devices: devices} }
  end

  def handle_info({:broadcast, _device}, state) do
    Registry.dispatch(RainMachine, "zones", fn entries ->
      for {pid, _} <- entries do
        Logger.debug("Broadcasting to pid #{inspect pid}")
        Process.send(pid, :rainmachine_update, [])
      end
    end)

    {:noreply, state}
  end

  def handle_call({:add_device, %{ip_address: ip_address} = device}, _from, %{devices: devices} = state) do
    {:reply, [], %{state | devices: Map.put(devices, ip_address, device)}}
  end

  def handle_call({:get_device, ip_address}, _from, %{devices: devices} = state) do
    {:reply, Map.get(devices, ip_address, nil), state}
  end
end



