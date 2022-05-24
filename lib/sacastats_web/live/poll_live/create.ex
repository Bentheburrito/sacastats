defmodule SacaStatsWeb.PollLive.Create do
  @moduledoc """
  LiveView for creating polls.
  """
  use SacaStatsWeb, :live_view
  use Phoenix.HTML

  alias SacaStats.{Poll, Repo, Utils}

  def render(assigns) do
    Phoenix.View.render(SacaStatsWeb.PollView, "create.html", assigns)
  end

  def mount(_params, session, socket) do
    user = session["user"]

    if is_nil(user) do
      {:ok,
      socket
      |> put_flash(:error, "You need to be logged in to create polls.")
      |> redirect(to: "/")}
    else
      changeset = Poll.changeset(%Poll{}, %{})

      {:ok,
       socket
       |> assign(:owner_discord_id, user["id"])
       |> assign(:changeset, changeset)
       |> assign(:prev_params, %{})}
    end
  end

  def handle_event("field_change", %{"poll" => params}, socket) do
    changeset = Poll.changeset(%Poll{}, params)

    {:noreply,
     socket
     |> assign(:changeset, changeset)
     |> assign(:prev_params, params)}
  end

  def handle_event("add_item", _params, socket) do
    params =
      Map.update(
        socket.assigns.prev_params,
        "items",
        %{"0" => %{}},
        &Map.put(&1, to_string(map_size(socket.assigns.prev_params["items"])), %{})
      )

    changeset = Poll.changeset(%Poll{}, params)

    {:noreply,
     socket
     |> assign(:changeset, changeset)
     |> assign(:prev_params, params)}
  end

  def handle_event("add_choice:" <> item_index, _params, socket) do
    IO.inspect socket.assigns.prev_params, label: "prev params add choice"
    IO.inspect socket.assigns.changeset, label: "changeset add choice"
    params =
      update_in(
        socket.assigns.prev_params,
        ["items", item_index, "choices"],
        fn
          nil -> %{"0" => %{}}
          choices -> Map.put(choices, to_string(map_size(choices)), %{})
        end
      )

    changeset = Poll.changeset(%Poll{}, params)

    {:noreply,
     socket
     |> assign(:changeset, changeset)
     |> assign(:prev_params, params)}
  end

  def handle_event("remove_item:" <> to_remove_index, _params, socket) do
    params =
      Map.update(
        socket.assigns.prev_params,
        "items",
        %{},
        &remove_at(&1, to_remove_index)
      )

    changeset = Poll.changeset(%Poll{}, params)

    {:noreply,
     socket
     |> assign(:changeset, changeset)
     |> assign(:prev_params, params)}
  end

  def handle_event("remove_choice:" <> indexes, _params, socket) do
    [item_index, choice_index] = String.split(indexes, ":")

    IO.inspect socket.assigns.prev_params, label: "prev params"
    IO.inspect item_index, label: "item index"

    params =
      update_in(
        socket.assigns.prev_params,
        ["items", item_index, "choices"],
        &remove_at(&1, choice_index)
      )
    IO.inspect params, label: "PARAMS"
    changeset = Poll.changeset(%Poll{}, params)

    {:noreply,
     socket
     |> assign(:changeset, changeset)
     |> assign(:prev_params, params)}
  end

  def handle_event("form_submit", _params, socket) do
    IO.inspect socket.assigns.changeset, label: "on submit changeset"
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
    items = inputs_for(form, :items)
    IO.inspect(items, label: "inputs for items encode")
    ~H"""
    <%= for {item, index} <- Enum.with_index(items) do %>
      <div class="poll-item">
        <button type="button"
          phx-click={"remove_item:#{index}"}
          class="btn-danger btn-sm remove-item-button">
          Remove Field
        </button>
        <%= encode_poll_item(assigns, item, index) %>
      </div>
    <% end %>
    """
  end

  defp encode_poll_item(assigns, %Phoenix.HTML.Form{} = item, item_index) do
    choices = inputs_for(item, :choices)

    ~H"""
    <h4><%= length(choices) == 0 && "Text" || "Multiple-Choice" %> Field</h4>

    <%= label item, :description %>
    <%= text_input item, :description %>
    <%= error_tag item, :description %>
    <ul>
      <%= for {choice, choice_index} <- Enum.with_index(choices) do %>
        <button type="button"
          phx-click={"remove_choice:#{item_index}:#{choice_index}"}
          class="btn-danger btn-sm remove-item-button">
          Remove Choice
        </button>
        <%= encode_poll_item_choice(assigns, choice) %>
      <% end %>
    </ul>
    <button type="button" phx-click={"add_choice:#{item_index}"} class="btn-info">Add Multiple-Choice Option</button>
    """
  end

  defp encode_poll_item_choice(assigns, %Phoenix.HTML.Form{} = choice) do
    ~H"""
    <li>
    <div class="d-inline">
      <%= label choice, :description, "Choice Description", class: "d-inline" %>
      <%= text_input choice, :description, class: "d-inline" %>
      <%= error_tag choice, :description %>
      </div>
    </li>
    """
  end

  defp remove_at(map, to_remove_index) do
    Enum.reduce(map, %{}, fn
     {index, item}, acc when index < to_remove_index -> Map.put(acc, index, item)
     {index, _item}, acc when index == to_remove_index -> acc
     {index, item}, acc when index > to_remove_index -> Map.put(acc, to_string(String.to_integer(index) - 1), item)
    end)
  end
end
