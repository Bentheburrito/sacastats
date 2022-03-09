defmodule SacaStatsWeb.PollController do
  use SacaStatsWeb, :controller

  require Logger

  alias SacaStats.Poll

  def create(conn, _params) do
    render(conn, "create.html")
  end

  def create_post(conn, params) do
    IO.inspect(params)
  end

  def view(conn, %{"id" => poll_id}) do
    case SacaStats.Repo.get(Poll, poll_id) do
      nil ->
        conn
        |> put_flash(:error, "That poll doesn't seem to exist.")
        |> redirect(to: current_path(conn))
      poll ->
        # need to load assocs?
        render(conn, "view.html", poll: poll)
    end
  end
end
