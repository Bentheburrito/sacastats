defmodule SacaStatsWeb.Router do
  use SacaStatsWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", SacaStatsWeb do
    pipe_through :browser

    get "/", PageController, :index
  end

  scope "/character", SacaStatsWeb do
    pipe_through :browser

    get "/", PageController, :characterhome
    get "/:character_name/:stat_type", PageController, :character
  end

  # Other scopes may use custom stacks.
  # scope "/api", SacaStatsWeb do
  #   pipe_through :api
  # end
end
