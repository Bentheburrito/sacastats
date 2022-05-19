defmodule SacaStatsWeb do
  @moduledoc """
  The entrypoint for defining your web interface, such
  as controllers, views, channels and so on.

  This can be used in your application as:

      use SacaStatsWeb, :controller
      use SacaStatsWeb, :view

  The definitions below will be executed for every view,
  controller, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below. Instead, define any helper function in modules
  and import those modules here.
  """

  def controller do
    quote do
      use Phoenix.Controller, namespace: SacaStatsWeb

      import Plug.Conn
      import SacaStatsWeb.Gettext
      alias SacaStatsWeb.Router.Helpers, as: Routes
    end
  end

  def view do
    quote do
      use Phoenix.View,
        root: "lib/sacastats_web/templates",
        namespace: SacaStatsWeb

      # Import convenience functions from controllers
      import Phoenix.Controller,
        only: [get_flash: 1, get_flash: 2, view_module: 1, view_template: 1]

      # Include shared imports and aliases for views
      unquote(view_helpers())

      import Phoenix.LiveView.Helpers
    end
  end

  def live_view do
    quote do
      use Phoenix.LiveView,
        layout: {SacaStatsWeb.LayoutView, "live.html"}

      unquote(view_helpers())
    end
  end

  def live_component do
    quote do
      use Phoenix.LiveComponent

      unquote(view_helpers())
    end
  end

  def router do
    quote do
      use Phoenix.Router

      import Plug.Conn
      import Phoenix.Controller
      import Phoenix.LiveView.Router
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
      import SacaStatsWeb.Gettext
    end
  end

  def generate_page_title(endpoint) do
    site_name = "Saca Stats"
    separator = " - "
    postfix = separator <> site_name
    endpoint_arr = String.split(endpoint, "/", trim: true)

    case length(endpoint_arr) do
      0 -> site_name
      _ -> generate_subpage_title(endpoint_arr, separator) <> postfix
    end
  end

  def generate_subpage_title([first | rest], separator)
      when first == "character" and length([first | rest]) > 1,
      do: generate_character_title([first | rest], separator)

  def generate_subpage_title(endpoint_arr, separator) do
    endpoint_arr
    |> Enum.map_join(separator, fn endpoint -> String.capitalize(endpoint) end)
  end

  def generate_character_title(endpoint_arr, separator) do
    endpoint_arr
    |> Enum.with_index()
    |> Enum.map(fn {endpoint, index} ->
      cond do
        index == 1 ->
          endpoint

        index > 1 ->
          String.capitalize(endpoint)

        true ->
          ""
      end
    end)
    |> Enum.filter(fn endpoint -> endpoint != "" end)
    |> Enum.join(separator)
  end

  defp view_helpers do
    quote do
      # Use all HTML functionality (forms, tags, etc)
      use Phoenix.HTML

      # Import LiveView and .heex helpers (live_render, live_patch, <.form>, etc)
      import Phoenix.LiveView.Helpers

      # Import basic rendering functionality (render, render_layout, etc)
      import Phoenix.View

      import SacaStatsWeb.ErrorHelpers
      import SacaStatsWeb.Gettext
      alias SacaStatsWeb.Router.Helpers, as: Routes
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
