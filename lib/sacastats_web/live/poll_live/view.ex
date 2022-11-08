defmodule SacaStatsWeb.PollLive.View do
  @moduledoc """
  LiveView for viewing polls as voters.
  """
  use SacaStatsWeb, :live_view
  use Phoenix.HTML

  alias Ecto.Multi
  alias SacaStats.Poll.Item.Vote
  alias SacaStats.Repo

  import SacaStatsWeb.PollLive

  require Logger

  def render(assigns) do
    Phoenix.View.render(SacaStatsWeb.PollView, "view.html", assigns)
  end

  def mount(%{"id" => id}, session, socket) do
    case get_poll(id) do
      nil ->
        {:ok,
         socket
         |> put_flash(:error, "The poll ID \"#{id}\" does not exist.")
         |> redirect(to: "/outfit/poll")}

      poll ->
        voter_id = get_voter_id(session)

        vote_changesets =
          for item <- poll.items, into: %{} do
            changeset =
              Vote.changeset(%Vote{}, %{"voter_discord_id" => voter_id, "item_id" => item.id})

            {item.id, changeset}
          end

        {:ok,
         socket
         |> assign(:poll, poll)
         |> assign(:vote_changesets, vote_changesets)
         |> assign(:user, session["user"] || session[:user])
         |> assign(:_csrf_token, session["_csrf_token"])}
    end
  end

  def handle_event("field_change", %{"vote" => params}, socket) do
    item_id = SacaStats.Utils.maybe_to_int(params["item_id"])
    changeset = Vote.changeset(%Vote{}, params)
    vote_changesets = Map.put(socket.assigns.vote_changesets, item_id, changeset)
    {:noreply, assign(socket, :vote_changesets, vote_changesets)}
  end

  def handle_event("form_submit", _params, socket) do
    transaction =
      socket.assigns.vote_changesets
      |> Stream.with_index()
      |> Enum.reduce(Multi.new(), fn {{_item_id, changeset}, index}, multi ->
        Multi.insert(multi, "vote_#{index}", changeset)
      end)

    case Repo.transaction(transaction) do
      {:ok, _changes} ->
        poll_id = socket.assigns.poll.id

        Phoenix.PubSub.broadcast(
          SacaStats.PubSub,
          "poll_vote:#{poll_id}",
          {:poll_vote, get_voter_id(socket.assigns)}
        )

        {:noreply, redirect(socket, to: "/outfit/poll/#{poll_id}/results")}

      {:error, failed_name, failed_value, _changes_so_far} ->
        Logger.info("Poll vote failed on #{failed_name}: #{inspect(failed_value)}")

        {:noreply,
         socket
         |> put_flash(:error, "There are problems with the poll. See the fields below.")
         |> assign(:vote_changesets, socket.assigns.vote_changesets)}
    end
  end

  def encode_poll_item_vote(assigns, %Phoenix.HTML.Form{data: %Vote{}} = vote_form, item) do
    voter_id = get_voter_id(assigns)
    choices = Repo.preload(item, :choices).choices

    ~H"""
    <h4><%= item.description %></h4>

    <%= if length(choices) > 0 do %>
      <%= for choice <- choices do %>
        <%= label do %>
          <%= radio_button vote_form, :content, choice.description,
            checked: vote_form.source.changes[:content] == choice.description %>
          <%= choice.description %>
        <% end %>
      <% end %>
    <% else %>
      <%= text_input vote_form, :content %>
      <%= error_tag vote_form, :content %>
    <% end %>

    <%= hidden_input vote_form, :voter_discord_id, value: voter_id %>
    <%= hidden_input vote_form, :item_id, value: item.id %>
    """
  end
end
