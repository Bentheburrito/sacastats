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

  @failed_to_save_message "Oops, something went wrong when saving your changes. Please try again soon."

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
           |> assign(:poll_changeset, Poll.update_changeset(poll))
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

  def handle_event("update-poll", %{"poll" => params}, socket) do
    update_poll(params, socket)
  end

  def handle_event("delete-poll", _params, socket) do
    case Repo.delete(socket.assigns.poll) do
      {:ok, _poll} ->
        {:noreply,
         socket
         |> put_flash(:info, "Successfully deleted poll.")
         |> redirect(to: "/outfit/poll")}

      {:error, changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, @failed_to_save_message)
         |> assign(:poll_changeset, changeset)}
    end
  end

  def handle_event("delete-allowed-voter", %{"id" => voter_id}, socket) do
    voter_id = String.to_integer(voter_id)
    new_allowed_voters = List.delete(socket.assigns.poll.allowed_voters, voter_id)

    update_poll(%{"allowed_voters" => new_allowed_voters}, socket)
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
           @failed_to_save_message
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

  defp update_poll(attrs, socket) do
    changeset = Poll.update_changeset(socket.assigns.poll, attrs)

    case Repo.update(changeset) do
      {:ok, poll} ->
        {:noreply,
         socket
         |> assign(:poll, poll)
         |> assign(:poll_changeset, Poll.update_changeset(poll))}

      {:error, changeset} ->
        IO.inspect(changeset)

        {:noreply,
         socket
         |> put_flash(:error, @failed_to_save_message)
         |> assign(:poll_changeset, changeset)}
    end
  end
end
