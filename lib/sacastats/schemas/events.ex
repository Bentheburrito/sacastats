defmodule SacaStats.Events do
  @moduledoc """
  Module encompassing ESS events
  """

  alias Ecto.Changeset

  @doc """
  Casts the given payload to an event struct.
  """
  @spec cast_event(String.t(), map()) ::
          {:ok, struct()} | {:error, :unknown_event} | {:error, :bad_payload}
  def cast_event(event_name, payload) do
    module = String.to_existing_atom("Elixir.SacaStats.Events.#{event_name}")
    Code.ensure_loaded(module)

    with true <- function_exported?(module, :changeset, 2),
         %Changeset{} = changeset <- module.changeset(struct(module), payload) do
      {:ok, changeset}
    else
      false -> {:error, :unknown_event}
    end
  rescue
    ArgumentError -> {:error, :module_no_exist}
  end
end
