defmodule SacaStatsWeb.PollLive.Manage do
  @moduledoc """
  LiveView for viewing polls as voters.
  """
  use SacaStatsWeb, :live_view
  use Phoenix.HTML

  alias SacaStats.{Poll, Repo}
  alias Poll.Item
  alias Item.Vote

  import SacaStatsWeb.PollLive

  require Logger

  def render(assigns) do
    Phoenix.View.render(SacaStatsWeb.PollView, "manage.html", assigns)
  end

  def mount(%{"id" => id}, session, socket) do
    case get_poll(id) do
      nil ->
        {:ok,
         socket
         |> put_flash(:error, "The poll ID \"#{id}\" does not exist.")
         |> redirect(to: "/outfit/poll")}

      %Poll{} = poll ->
        voter_id = get_voter_id(session)

        if poll_owner?(voter_id, poll) do
          vote_table_values =
            for %Item{} = item <- poll.items,
                %Vote{} = vote <- item.votes,
                reduce: %{} do
              mapped_votes ->
                Map.update(
                  mapped_votes,
                  vote.voter_discord_id,
                  %{item.id => vote},
                  &Map.put(&1, item.id, vote)
                )
            end

          Phoenix.PubSub.subscribe(SacaStats.PubSub, "poll_vote:#{poll.id}")

          {:ok,
           socket
           |> assign(:poll, poll)
           |> assign(:item_map, Map.new(poll.items, &{&1.id, &1}))
           |> assign(:vote_table_values, vote_table_values)
           |> assign(:user, session["user"] || session[:user])
           |> assign(:_csrf_token, session["_csrf_token"])}
        else
          {:ok,
           socket
           |> put_flash(:error, "You do not have permission to view that page.")
           |> redirect(to: "/outfit/poll/#{id}")}
        end
    end
  end

  def handle_event("update-item", %{"item" => params}, socket) do
    item_id = String.to_integer(params["id"])
    item = Map.get(socket.assigns.item_map, item_id)
    changeset = Item.update_changeset(item, params)

    case Repo.update(changeset) do
      {:ok, item} ->
        item_map = Map.put(socket.assigns.item_map, item.id, item)

        {:noreply, assign(socket, :item_map, item_map)}

      {:error, _changeset} ->
        {:noreply,
         put_flash(
           socket,
           :error,
           "Oops, something went wrong when saving your changes. Please try again soon."
         )}
    end
  end

  # handle new votes as they come in.
  def handle_info({:poll_vote, _user_id}, socket) do
    %Poll{} = poll = get_poll(socket.assigns.poll.id)
    {:noreply, assign(socket, :poll, poll)}
  end

  def handle_info(_message, socket) do
    {:noreply, socket}
  end
end
