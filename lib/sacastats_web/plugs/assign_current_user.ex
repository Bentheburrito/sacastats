defmodule SacaStatsWeb.Plugs.AssignCurrentUser do
  @moduledoc false

  import Plug.Conn

  def assign_current_user(conn, _) do
    user = get_session(conn, :user)

    assign(conn, :user, user)
  end
end
