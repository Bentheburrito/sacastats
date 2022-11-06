defmodule SacaStatsWeb.Router do
  use SacaStatsWeb, :router
  import SacaStatsWeb.Plugs.AssignCurrentUser

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {SacaStatsWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :assign_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", SacaStatsWeb do
    pipe_through :browser

    get "/", PageController, :index
    get "/account", PageController, :account
    get "/login", PageController, :login
    get "/login/new", PageController, :login_discord
    get "/login/redir", PageController, :login_discord_callback
    get "/logout", PageController, :logout_discord
  end

  scope "/character", SacaStatsWeb do
    pipe_through :browser

    live "/", CharacterLive.Search
    get "/:character_name", CharacterController, :base
    get "/:character_name/:stat_type", CharacterController, :character
    live "/:character_name/sessions/:login_timestamp", SessionLive.View
    post "/:character_name/:stat_type", CharacterController, :character_post
    post "/:character_name/:stat_type/favorite", CharacterController, :add_favorite
    post "/:character_name/:stat_type/unfavorite", CharacterController, :remove_favorite
    post "/:character_name/:stat_type/:optional", CharacterController, :character_optional_post
    post "/:character_name/:stat_type/:optional/favorite", CharacterController, :add_favorite
    post "/:character_name/:stat_type/:optional/unfavorite", CharacterController, :remove_favorite
  end

  scope "/outfit", SacaStatsWeb do
    pipe_through :browser

    get "/", OutfitController, :general
    get "/poll", OutfitController, :poll_lookup
    live "/poll/create", PollLive.Create
    live "/poll/:id/results", PollLive.Results
    live "/poll/:id", PollLive.View
  end

  # Other scopes may use custom stacks.
  # scope "/api", SacaStatsWeb do
  #   pipe_through :api
  # end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser
      live_dashboard "/dashboard", metrics: SacaStatsWeb.Telemetry
    end
  end

  # Enables the Swoosh mailbox preview in development.
  #
  # Note that preview only shows emails that were sent by the same
  # node running the Phoenix server.
  if Mix.env() == :dev do
    scope "/dev" do
      pipe_through :browser

      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
