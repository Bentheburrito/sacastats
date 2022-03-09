defmodule SacaStatsWeb.PollLive.Create do
  use Phoenix.LiveView
  use Phoenix.HTML

  alias SacaStats.Poll
  alias SacaStats.PollItem.{MultiChoice, Text}

  def render(assigns) do
    Phoenix.View.render(SacaStatsWeb.PollView, "create.html", assigns)
  end

  def mount(_params, _session, socket) do
    changeset = Poll.changeset(%Poll{})

    {:ok, assign(socket, :changeset, changeset)}
  end

  def handle_event("field_change", %{"poll" => params}, socket) do

    IO.inspect params, label: "PARAMS"

    changeset = #Ecto.Changeset.change(socket.assigns.changeset, params)
      socket.assigns.changeset
      |> Poll.changeset(params)
      |> Map.put(:action, :insert)

    IO.inspect(changeset, label: "Updated Changeset")
    {:noreply, assign(socket, :changeset, changeset)}
    # {:noreply, socket}
  end

  def handle_event("add_text", _params, socket) do
    {text_items, _mc_items, new_position} = fetch_items_and_pos(socket.assigns.changeset.changes)
    item_changes = %{"position" => new_position}
    changes = %{text_items: [Text.changeset(%Text{}, item_changes) | text_items]}
    IO.inspect changes, label: "PROBLEMATIC CHANGES"

    changeset = Ecto.Changeset.change(socket.assigns.changeset, changes)
      # socket.assigns.changeset
      # |> Poll.changeset(changes)
      # |> Map.put(:action, :insert)

    IO.inspect(changeset, label: "add_text Updated CHANGESET")
    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("add_multi", _params, socket) do
    {_txt_items, multi_choice_items, new_position} = fetch_items_and_pos(socket.assigns.changeset.changes)
    item_changes = %{"position" => new_position}
    changes = %{multi_choice_items: [MultiChoice.changeset(%MultiChoice{}, item_changes) | multi_choice_items]}

    changeset = Ecto.Changeset.change(socket.assigns.changeset, changes)
    IO.inspect(changeset, label: "add_multi Updated CHANGESET!")
    {:noreply, assign(socket, :changeset, changeset)}
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
    IO.inspect text_item, label: "ENCODING TEXT ITEM"
    ~H"""
    <h4>Text Field <%=text_item.source.changes.position%></h4>
    <label>Description: <%= text_input text_item, :description %></label>
    <%= hidden_input text_item, :position, value: text_item.source.changes.position %>
    """
  end

  defp encode_poll_item(assigns, %Phoenix.HTML.Form{data: %MultiChoice{}} = multi_choice_item) do
    ~H"""
    <h4>Multiple Choice Field <%=multi_choice_item.source.changes.position%></h4>
    <label>Description: <%= text_input multi_choice_item, :description %></label>
    <label>Choices, separated by commas: <%= text_input multi_choice_item, :choices %></label>
    <%= hidden_input multi_choice_item, :position, value: multi_choice_item.source.changes.position %>
    """
  end

  defp fetch_items_and_pos(changes) do
    text_items = Map.get(changes, :text_items, [])
    multi_choice_items = Map.get(changes, :multi_choice_items, [])
    new_position = length(text_items) + length(multi_choice_items) + 1

    {text_items, multi_choice_items, new_position}
  end
end
