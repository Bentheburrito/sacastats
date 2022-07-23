defmodule SacaStatsWeb.PollLive.View do
  @moduledoc """
  LiveView for viewing polls as voters.
  """
  use SacaStatsWeb, :live_view
  use Phoenix.HTML

  alias Ecto.Multi
  alias SacaStats.{Poll, Repo}
  alias SacaStats.Poll.Item
  alias SacaStats.Poll.Item.Vote

  import SacaStatsWeb.PollLive

  require Logger

  @content_cant_be_blank [content: {"can't be blank", [validation: :required]}]

  def render(assigns) do
    Phoenix.View.render(SacaStatsWeb.PollView, "view.html", assigns)
  end

  def mount(%{"id" => id}, session, socket) do
    build_poll_assigns_or_redirect(get_poll(id), session, socket)
  end

  def build_poll_assigns_or_redirect(nil, _session, socket) do
    {:ok,
     socket
     |> put_flash(:error, "That poll does not exist.")
     |> redirect(to: "/outfit/poll")}
  end

  def build_poll_assigns_or_redirect(%Poll{id: id} = poll, session, socket) do
    voter_id = get_voter_id(session)

    cond do
      not is_nil(poll.close_poll_at) and
          DateTime.compare(DateTime.utc_now(), poll.close_poll_at) == :gt ->
        {:ok,
         socket
         |> put_flash(:info, "This poll is no longer taking votes.")
         |> redirect(to: "/outfit/poll/#{id}/results")}

      not allowed_voter?(voter_id, poll) and not poll_owner?(voter_id, poll) ->
        {:ok,
         socket
         |> put_flash(
           :error,
           "You are not allowed to vote in this poll. If you believe this is a mistake, contact the owner of the poll."
         )
         |> redirect(to: "/outfit/poll")}

      has_voted?(voter_id, poll) ->
        {:ok, redirect(socket, to: "/outfit/poll/#{id}/results")}

      :else ->
        vote_changesets =
          for %Item{} = item <- poll.items, into: %{} do
            changeset =
              Vote.changeset(%Vote{}, %{
                "voter_discord_id" => voter_id,
                "item_id" => item.id
              })

            {item.id, changeset}
          end

        item_map = Map.new(poll.items, &{&1.id, &1})

        {:ok,
         socket
         |> assign(:poll, poll)
         |> assign(:vote_changesets, vote_changesets)
         |> assign(:item_map, item_map)
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
      |> Enum.reduce(Multi.new(), fn {{item_id, changeset}, index}, multi ->
        is_optional? = socket.assigns.item_map[item_id].optional == true

        if is_optional? and Map.get(changeset.changes, :content) in [nil, ""] do
          multi
        else
          Multi.insert(multi, "vote_#{index}", changeset)
        end
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

      {:error, _failed_name, %Ecto.Changeset{errors: @content_cant_be_blank}, _changes_so_far} ->
        {:noreply,
         socket
         |> put_flash(:error, "Fields marked with * are required.")
         |> assign(:vote_changesets, socket.assigns.vote_changesets)}

      {:error, failed_name, failed_value, _changes_so_far} ->
        Logger.info("Poll vote failed on #{failed_name}: #{inspect(failed_value)}")

        {:noreply,
         socket
         |> put_flash(
           :error,
           "There are problems with the poll. Please double check everything and try again."
         )
         |> assign(:vote_changesets, socket.assigns.vote_changesets)}
    end
  end

  def encode_poll_item_vote(assigns, %Phoenix.HTML.Form{data: %Vote{}} = vote_form, item) do
    voter_id = get_voter_id(assigns)
    choices = Repo.preload(item, :choices).choices

    ~H"""
    <h4>
      <%= unless item.optional do %>
        <b class="text-danger">*</b>
      <% end %>
      <%= item.description %>
    </h4>

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
    <% end %>
    <%= error_tag vote_form, :content %>

    <%= hidden_input vote_form, :voter_discord_id, value: voter_id %>
    <%= hidden_input vote_form, :item_id, value: item.id %>
    """
  end
end
