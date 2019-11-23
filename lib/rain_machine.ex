defmodule RainMachine do
  @moduledoc """
  Documentation for RainMachine.
  """

  alias RainMachine.Device
  alias RainMachine.State

  def get_device(ip_address) do
    State.get_device(ip_address)
  end

  def get_zone(%{zones: zones}, uid) do
    uid = String.to_integer(uid)
    Enum.find(zones, fn z -> 
      z.uid == uid end)
  end

  def start_zone(device, zone) do
    Device.start_zone(device, zone)
  end

  def stop_zone(device, zone) do
    Device.stop_zone(device, zone)
  end

  def device_subscribe(ip_address, password) do
    Registry.register(RainMachine, ip_address, [])

    with true <- is_nil(State.get_device(ip_address)),
         {:ok, device} <- Device.create(ip_address, password) do

      State.add_device(device)
    end
  end
end
