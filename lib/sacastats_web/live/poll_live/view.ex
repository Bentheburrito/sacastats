defmodule SacaStatsWeb.PollLive.View do
  use SacaStatsWeb, :live_view
  use Phoenix.HTML

  alias SacaStats.Poll
  alias SacaStats.PollItem.{MultiChoice, Text}
  alias SacaStats.Repo

  def render(assigns) do
    Phoenix.View.render(SacaStatsWeb.PollView, "view.html", assigns)
  end

  def mount(%{"id" => id}, session, socket) do
    %Poll{} = poll = Repo.get(Poll, id) |> Repo.preload([:text_items, :multi_choice_items])

    changeset = Poll.new_vote_changeset(poll, %{})

    {:ok, socket
      |> assign(:poll, poll)
      |> assign(:changeset, changeset)
      |> assign(:user, session["user"])
      |> assign(:prev_params, %{})
      |> assign(:_csrf_token, session["_csrf_token"])}
    end

  # for when owner is viewing and wants to see votes come in live
  def handle_info({:poll_vote, user_id}, socket) do

    {:noreply, socket}
  end

  def handle_event("field_change", %{"poll" => params}, socket) do
    changeset = Poll.new_vote_changeset(socket.assigns.changeset, params)
    {:noreply, socket
      |> assign(:changeset, changeset)
      |> assign(:prev_params, params)}
  end

  def handle_event("form_submit", _params, socket) do
    new_changes =
      socket.assigns.changeset.changes
      |> Map.update(:text_items, [], &Enum.zip_with(&1, socket.assigns.poll.text_items, fn new, cur ->
        cur_votes = Map.get(cur, :votes, %{})
        new_votes = Map.get(new.changes, :votes, %{})
        %{new | changes: %{votes: Map.merge(cur_votes, new_votes)}}
      end))
      |> Map.update(:multi_choice_items, [], &Enum.zip_with(&1, socket.assigns.poll.multi_choice_items, fn new, cur ->
        cur_votes = Map.get(cur, :votes, %{})
        new_votes = Map.get(new.changes, :votes, %{})
        %{new | changes: %{votes: Map.merge(cur_votes, new_votes)}}
      end))

    changeset =
      socket.assigns.changeset
      |> Map.put(:changes, new_changes)
      |> Map.put(:action, :update)

    IO.inspect Ecto.Changeset.apply_changes(changeset), label: "ON SUBMIT Changeset APPLIED"

    case Repo.update(changeset) do
      {:ok, %Poll{id: id}} ->
        {:noreply, redirect(socket, to: "/outfit/poll/#{id}")}

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

    ~H"""
    <h4><%= position %>. Text Field</h4>

    <%= label text_item, :votes, text_item.data.description %>
    <%= text_input text_item, :votes_voter, name: "poll[text_items][#{text_item.index}][votes][#{voter_id}]", value: text_item.source.changes[:votes][voter_id] %>
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
      <%= radio_button multi_choice_item, :votes_voter, choice, name: item_name, id: "multi_choice_#{position}_#{choice}", checked: multi_choice_item.source.changes[:votes][voter_id] == choice %>
      <label class="radio-label" for={"multi_choice_#{position}_#{choice}"}><%= choice %></label>
    <% end %>

    <%= hidden_input multi_choice_item, :position, value: position %>
    <%= hidden_input multi_choice_item, :id, value: multi_choice_item.data.id %>
    """
  end

  defp get_voter_id(%{user: %{"id" => user_id}}), do: user_id
  defp get_voter_id(assigns), do: "anonymous_#{assigns[:_csrf_token]}"
end
