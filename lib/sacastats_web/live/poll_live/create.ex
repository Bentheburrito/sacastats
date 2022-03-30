defmodule SacaStatsWeb.PollLive.Create do
  @moduledoc """
  LiveView for creating polls.
  """
  use SacaStatsWeb, :live_view
  use Phoenix.HTML

  alias SacaStats.Poll
  alias SacaStats.PollItem.{MultiChoice, Text}
  alias SacaStats.Repo
  alias SacaStats.Utils

  def render(assigns) do
    Phoenix.View.render(SacaStatsWeb.PollView, "create.html", assigns)
  end

  def mount(_params, session, socket) do
    user = session["user"]
    init_changes = %{"owner_discord_id" => user["id"]}

    if is_nil(user) do
      {:ok,
       socket
       |> put_flash(:error, "You need to be logged in to create polls.")
       |> redirect(to: "/")}
    else
      changeset = Poll.changeset(%Poll{}, init_changes)

      {:ok,
       socket
       |> assign(:changeset, changeset)
       |> assign(:prev_params, init_changes)}
    end
  end

  def handle_event("field_change", %{"poll" => params}, socket) do
    changeset =
      %Poll{}
      |> Poll.changeset(params)

    {:noreply,
     socket
     |> assign(:changeset, changeset)
     |> assign(:prev_params, params)}
  end

  def handle_event("add_text", _params, socket) do
    next_position = get_next_position(socket.assigns.changeset.changes)

    next_index =
      socket.assigns.prev_params
      |> Map.get("text_items", %{})
      |> map_size()
      |> Integer.to_string()

    params =
      Map.update(
        socket.assigns.prev_params,
        "text_items",
        %{"0" => %{"position" => next_position}},
        &Map.put(&1, next_index, %{"position" => next_position})
      )

    changeset = Poll.changeset(%Poll{}, params)

    {:noreply,
     socket
     |> assign(:changeset, changeset)
     |> assign(:prev_params, params)}
  end

  def handle_event("add_multi", _params, socket) do
    next_position = get_next_position(socket.assigns.changeset.changes)

    next_index =
      socket.assigns.prev_params
      |> Map.get("multi_choice_items", %{})
      |> map_size()
      |> Integer.to_string()

    params =
      Map.update(
        socket.assigns.prev_params,
        "multi_choice_items",
        %{"0" => %{"position" => next_position}},
        &Map.put(&1, next_index, %{"position" => next_position})
      )

    changeset = Poll.changeset(%Poll{}, params)

    {:noreply,
     socket
     |> assign(:changeset, changeset)
     |> assign(:prev_params, params)}
  end

  def handle_event("remove_item:" <> to_remove_position, _params, socket) do
    to_remove_position = String.to_integer(to_remove_position)

    params =
      socket.assigns.prev_params
      |> Map.update("text_items", %{}, &remove_item(&1, to_remove_position))
      |> Map.update("multi_choice_items", %{}, &remove_item(&1, to_remove_position))

    changeset = Poll.changeset(%Poll{}, params)

    {:noreply,
     socket
     |> assign(:changeset, changeset)
     |> assign(:prev_params, params)}
  end

  def handle_event("form_submit", _params, socket) do
    case Repo.insert(socket.assigns.changeset) do
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

    poll_items =
      Enum.sort_by(text_items ++ multi_choice_items, fn a -> a.source.changes.position end)

    ~H"""
    <%= for item <- poll_items do %>
      <div class="poll-item">
        <button type="button"
          phx-click={"remove_item:#{item.source.changes.position}"}
          class="btn-danger btn-sm remove-item-button">
          Remove Field
        </button>
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

    choices_value =
      if is_list(multi_choice_item.source.changes[:choices]) do
        Enum.join(multi_choice_item.source.changes[:choices], ", ")
      else
        multi_choice_item.source.changes[:choices]
      end

    ~H"""
    <h4><%= position %>. Multiple-Choice Field</h4>

    <%= label multi_choice_item, :description %>
    <%= text_input multi_choice_item, :description %>
    <%= error_tag multi_choice_item, :description %>

    <%= label multi_choice_item, :choices %>
    <%= text_input multi_choice_item, :choices, value: choices_value, placeholder: "Enter choices separated by commas. (e.g. \"option one, option two, option three\")" %>
    <%= error_tag multi_choice_item, :choices %>

    <%= hidden_input multi_choice_item, :position, value: position %>
    """
  end

  defp get_next_position(changes) do
    text_items = Map.get(changes, :text_items, [])
    multi_choice_items = Map.get(changes, :multi_choice_items, [])
    length(text_items) + length(multi_choice_items) + 1
  end

  defp remove_item(items, position) when is_integer(position) do
    for {index, %{"position" => item_pos} = item} <- items,
        item_pos = Utils.maybe_to_int(item_pos),
        position != item_pos,
        into: %{} do
      if item_pos > position do
        {item_pos - 1, %{item | "position" => item_pos - 1}}
      else
        {index, item}
      end
    end
  end
end
