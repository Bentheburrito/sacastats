defmodule SacaStatsWeb.PollLive.Results do
  @moduledoc """
  LiveView for viewing poll results.
  """
  use SacaStatsWeb, :live_view
  use Phoenix.HTML

  alias SacaStats.Poll

  import SacaStatsWeb.PollLive

  require Logger

  def render(assigns) do
    Phoenix.View.render(SacaStatsWeb.PollView, "results.html", assigns)
  end

  def mount(%{"id" => id}, _session, socket) do
    %Poll{} = poll = get_poll(id)

    IO.inspect "poll_vote:#{poll.id}"
    Phoenix.PubSub.subscribe(SacaStats.PubSub, "poll_vote:#{poll.id}")

    {:ok, assign(socket, :poll, poll)}
  end

  # handle new votes as they come in.
  def handle_info({:poll_vote, _user_id}, socket) do
    IO.inspect "GOT POLL VOTE MESSAGE"
    %Poll{} = poll = get_poll(socket.assigns.poll.id)
    {:noreply, assign(socket, :poll, poll)}
  end

  def handle_info(message, socket) do
    IO.inspect(message, label: "CATCH ALL WITH MESSAGE")
    {:noreply, socket}
  end
end
