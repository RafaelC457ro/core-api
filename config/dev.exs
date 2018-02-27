use Mix.Config

config :herenow, HerenowWeb.Endpoint,
  http: [port: 4000],
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  watchers: []

config :logger, :console, format: "[$level] $message\n"

config :phoenix, :stacktrace_depth, 20

config :herenow, Herenow.Mailer, adapter: Bamboo.LocalAdapter

config :herenow, captcha: Herenow.Captcha.HTTPAdapter

import_config "dev.secret.exs"
