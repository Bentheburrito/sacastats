defmodule SacaStatsWeb.PageController do
  use SacaStatsWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
