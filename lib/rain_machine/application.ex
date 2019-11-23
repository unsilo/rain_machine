defmodule RainMachine.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      {Registry, keys: :duplicate, name: RainMachine},
      RainMachine.State
    ]

    opts = [strategy: :one_for_one, name: RainMachine.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
