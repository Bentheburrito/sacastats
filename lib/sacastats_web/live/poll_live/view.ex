defmodule SacaStatsWeb.PollLive.View do
  @moduledoc """
  LiveView for viewing polls, either as voters, or the owner monitoring results as they come in.
  """
  use SacaStatsWeb, :live_view
  use Phoenix.HTML

  alias Ecto.Multi
  alias SacaStats.{Poll, Repo}
  alias SacaStats.Poll.{Item, Vote}

  def render(assigns) do
    Phoenix.View.render(SacaStatsWeb.PollView, "view.html", assigns)
  end

  def mount(%{"id" => id}, session, socket) do
    %Poll{} = poll =
      Poll
      |> Repo.get(id)
      |> Repo.preload([items: [:choices, :votes]])

    voter_id = not is_nil(session["user"]) && session["user"]["id"] || 0

    vote_changesets = for item <- poll.items, into: %{} do
      changeset = Vote.changeset(%Vote{}, %{"voter_discord_id" => voter_id, "item_id" => item.id})
      {item.id, changeset}
    end

    {:ok,
     socket
     |> assign(:poll, poll)
     |> assign(:vote_changesets, vote_changesets)
     |> assign(:user, session["user"])
     |> assign(:_csrf_token, session["_csrf_token"])}
  end

  # for when owner is viewing and wants to see votes come in live
  def handle_info({:poll_vote, user_id}, socket) do
    {:noreply, socket}
  end

  def handle_event("field_change", %{"vote" => params}, socket) do
    changeset = Vote.changeset(%Vote{}, params)
    vote_changesets = Map.put(socket.assigns.vote_changesets, params["item_id"], changeset)
    {:noreply, assign(socket, :vote_changesets, vote_changesets)}
  end

  def handle_event("form_submit", _params, socket) do
    transaction =
      Enum.reduce(socket.assigns.vote_changesets, Multi.new(), fn changeset, multi ->
        Multi.insert(multi, :vote, changeset)
      end)

    case Repo.transaction(changeset) do
      {:ok, _} ->
        {:noreply, redirect(socket, to: "/outfit/poll/#{id}/results")}

      {:error, changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, "There are problems with the poll. See the fields below.")
         |> assign(:changeset, changeset)}
    end
  end

  def encode_poll_items(form, assigns) do
    text_items = inputs_for(form, :text_items)
    multi_choice_items = inputs_for(form, :multi_choice_items)

    poll_items = Enum.sort_by(text_items ++ multi_choice_items, fn a -> a.data.position end)

    ~H"""
    <%= for item <- poll_items do %>
      <div class="poll-item" phx-change={"field_change:#{item.data.position}"}>
        <%= encode_poll_item(assigns, item) %>
      </div>
    <% end %>
    """
  end

  defp encode_poll_item(assigns, %Phoenix.HTML.Form{data: %Text{}} = text_item) do
    position = text_item.data.position
    voter_id = get_voter_id(assigns)
    text_name = "poll[text_items][#{text_item.index}][votes][#{voter_id}]"
    text_value = text_item.source.changes[:votes][voter_id]

    ~H"""
    <h4><%= position %>. Text Field</h4>

    <%= label text_item, :votes, text_item.data.description %>
    <%= text_input text_item, :votes_voter, name: text_name, value: text_value %>
    <%= error_tag text_item, :votes %>

    <%= hidden_input text_item, :position, value: position %>
    <%= hidden_input text_item, :id, value: text_item.data.id %>
    """
  end

  defp encode_poll_item(assigns, %Phoenix.HTML.Form{data: %MultiChoice{}} = multi_choice_item) do
    position = multi_choice_item.data.position
    voter_id = get_voter_id(assigns)
    item_name = "poll[multi_choice_items][#{multi_choice_item.index}][votes][#{voter_id}]"

    ~H"""
    <h4><%= position %>. Multiple-Choice Field</h4>

    <%= label multi_choice_item, multi_choice_item.data.description %>
    <%= for choice <- multi_choice_item.data.choices do %>
      <%= radio_button multi_choice_item, :votes_voter, choice,
        name: item_name,
        id: "multi_choice_#{position}_#{choice}",
        checked: multi_choice_item.source.changes[:votes][voter_id] == choice %>
      <label class="radio-label" for={"multi_choice_#{position}_#{choice}"}><%= choice %></label>
    <% end %>

    <%= hidden_input multi_choice_item, :position, value: position %>
    <%= hidden_input multi_choice_item, :id, value: multi_choice_item.data.id %>
    """
  end

  defp combine_votes(new_items, items) do
    Enum.zip_with(new_items, items, fn {_index, new}, cur ->
      cur_votes = Map.get(cur, :votes, %{})
      Map.update(new, "votes", cur_votes, &Map.merge(cur_votes, &1))
    end)
  end

  defp get_voter_id(%{user: %{"id" => user_id}}), do: user_id
  defp get_voter_id(assigns), do: "anonymous_#{assigns[:_csrf_token]}"
end
