defmodule RainMachineTest do
  use ExUnit.Case
  doctest RainMachine

  test "it can get zones" do
    zones = RainMachine.get_zones()
    assert  is_list(zones)
    refute Enum.empty?(zones)
  end
end
