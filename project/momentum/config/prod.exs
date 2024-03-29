import Config

config :momentum, etrade_api_url: "https://api.etrade.com"

# Do not print debug messages in production
config :logger, level: :info

# Finally import the config/prod.secret.exs which loads secrets
# and configuration from environment variables.
import_config "prod.secret.exs"
