defmodule SacaStats.EventTracker.Supervisor do
  use DynamicSupervisor

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl DynamicSupervisor
  def init(_init_arg) do
    SacaStats.EventTracker.Manager.begin(self())
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
