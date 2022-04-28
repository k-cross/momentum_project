import Config

config :momentum, etrade_api_url: "https://apisb.etrade.com"

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

import_config "dev.secret.exs"
