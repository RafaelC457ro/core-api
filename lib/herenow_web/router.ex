defmodule HerenowWeb.Router do
  use HerenowWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
    plug PlugSecex, except: ["content-security-policy"]
  end

  scope "/v1", HerenowWeb do
    pipe_through :api

    resources "/clients", ClientController, only: [:create]
    post "/verified-clients", ClientController, :verify
    post "/clients/request-activation", ClientController, :request_activation
    post "/clients/password-recovery", ClientController, :recover_password

    post "/auth/identity", AuthController, :create
  end

  if Mix.env() == :dev do
    forward "/sent_emails", Bamboo.EmailPreviewPlug
  end
end
