defmodule SacaStatsWeb.PollLive.Create do
  use SacaStatsWeb, :live_view
  use Phoenix.HTML

  alias SacaStats.Poll
  alias SacaStats.PollItem.{MultiChoice, Text}
  alias SacaStats.Repo

  def render(assigns) do
    Phoenix.View.render(SacaStatsWeb.PollView, "create.html", assigns)
  end

  def mount(_params, _session, socket) do
    changeset = Poll.changeset(%Poll{})

    {:ok, socket
      |> assign(:changeset, changeset)
      |> assign(:prev_params, %{})}
  end

  def handle_event("field_change", %{"poll" => params}, socket) do
    IO.inspect params, label: "PARAMS"
    changeset =
      %Poll{}
      |> Poll.changeset(params)

    {:noreply, socket
      |> assign(:changeset, changeset)
      |> assign(:prev_params, params)}
  end

  def handle_event("add_text", _params, socket) do
    new_position = get_next_position(socket.assigns.changeset.changes)

    params = Map.update(
      socket.assigns.prev_params,
      "text_items",
      %{"0" => %{"position" => new_position}},
      &Map.put(&1, new_position, %{"position" => new_position})
    )

    changeset = Poll.changeset(%Poll{}, params)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("add_multi", _params, socket) do
    new_position = get_next_position(socket.assigns.changeset.changes)

    params = Map.update(
      socket.assigns.prev_params,
      "multi_choice_items",
      %{"0" => %{"position" => new_position}},
      &Map.put(&1, new_position, %{"position" => new_position})
    )

    changeset = Poll.changeset(%Poll{}, params)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("form_submit", _params, socket) do
    case Repo.insert(socket.assigns.changeset) do
      {:ok, %Poll{id: id}} ->
        {:noreply, redirect(socket, to: "/outfit/poll/view/#{id}")}
      {:error, changeset} ->
        IO.inspect changeset, label: "POST-ERROR CHANGESET"
        {:noreply,
          socket
          |> put_flash(:error, "There are problems with the poll. See the fields below.")
          |> assign(:changeset, changeset)}
    end
  end

  def encode_poll_items(form, assigns) do
    text_items = inputs_for(form, :text_items)
    multi_choice_items = inputs_for(form, :multi_choice_items)

    poll_items = Enum.sort_by(text_items ++ multi_choice_items, fn a -> a.source.changes.position end)

    ~H"""
    <%= for item <- poll_items do %>
      <div class="poll-item" phx-change={"field_change:#{item.source.changes.position}"}>
        <%= encode_poll_item(assigns, item) %>
      </div>
    <% end %>
    """
  end

  defp encode_poll_item(assigns, %Phoenix.HTML.Form{data: %Text{}} = text_item) do
    position = text_item.source.changes.position

    ~H"""
    <h4><%= position %>. Text Field</h4>

    <%= label text_item, :description %>
    <%= text_input text_item, :description %>
    <%= error_tag text_item, :description %>

    <%= hidden_input text_item, :position, value: position %>
    """
  end

  defp encode_poll_item(assigns, %Phoenix.HTML.Form{data: %MultiChoice{}} = multi_choice_item) do
    position = multi_choice_item.source.changes.position

    ~H"""
    <h4><%= position %>. Multiple-Choice Field</h4>

    <%= label multi_choice_item, :description %>
    <%= text_input multi_choice_item, :description %>
    <%= error_tag multi_choice_item, :description %>

    <%= label multi_choice_item, :choices %>
    <%= text_input multi_choice_item, :choices %>
    <%= error_tag multi_choice_item, :choices %>

    <%= hidden_input multi_choice_item, :position, value: position %>
    """
  end

  defp get_next_position(changes) do
    text_items = Map.get(changes, :text_items, [])
    multi_choice_items = Map.get(changes, :multi_choice_items, [])
    length(text_items) + length(multi_choice_items) + 1
  end
end
