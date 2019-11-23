use Mix.Config

config :rain_machine, RainMachine.Device,
  use_mock_data: false

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

import_config "#{Mix.env()}.exs"
import_config "#{Mix.env()}.secret.exs"
