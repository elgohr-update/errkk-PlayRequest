defmodule PRWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :pr

  @session_options [
    store: :cookie,
    key: "_pr_web_key",
    signing_salt: "ZG+jiBR2",
    same_site: "None"
  ]

  socket("/live", Phoenix.LiveView.Socket,
    websocket: [timeout: 45_000, connect_info: [session: @session_options], log: false],
    longpoll: false
  )

  socket("/socket", PRWeb.UserSocket,
    websocket: [timeout: 45_000, connect_info: [session: @session_options], log: false],
    longpoll: false
  )

  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phx.digest
  # when deploying your static files in production.
  plug(Plug.Static,
    at: "/",
    from: :pr,
    gzip: false,
    only: PRWeb.static_paths()
  )

  plug(LoggerJSON.Plug)

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    socket("/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket)
    plug(Phoenix.LiveReloader)
    plug(Phoenix.CodeReloader)
  end

  plug(Phoenix.LiveDashboard.RequestLogger,
    param_key: "request_logger",
    cookie_key: "request_logger"
  )

  plug(Plug.RequestId)
  # Log level debug, cos Plug.LoggerJSON logs requests for non-dev
  plug(Plug.Telemetry, event_prefix: [:phoenix, :endpoint], log: :debug)

  plug(Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()
  )

  plug(Plug.MethodOverride)
  plug(Plug.Head)

  # The session will be stored in the cookie and signed,
  # this means its contents can be read but not tampered with.
  # Set :encryption_salt if you would also like to encrypt it.
  plug(Plug.Session, @session_options)

  plug(PRWeb.Router)
end
