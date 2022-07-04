defmodule SacaStats.EventTracker.Manager do
  @moduledoc """
  Manages `EventTracker`s health by collecting reports, and instructing them to restart if they fail a health report.
  """
  use GenServer

  require Logger

  alias SacaStats.EventTracker
  alias SacaStats.EventTracker.{Manager, Report}

  @report_interval_ms 15 * 1000

  @margins_of_error %{
    event_counts: %{
      PS2.gain_experience() => 25,
      PS2.death() => 10,
      PS2.vehicle_destroy() => 10,
      PS2.player_login() => 5,
      PS2.player_logout() => 5,
      PS2.player_facility_capture() => 2,
      PS2.player_facility_defend() => 2,
      PS2.battle_rank_up() => 1,
      PS2.metagame_event() => 1,
      PS2.continent_unlock() => 0,
      PS2.continent_lock() => 0
    }
  }

  defstruct supervisor: SacaStats.EventTracker.Supervisor, began?: false

  ### API

  def start_link(opts) when is_list(opts) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, %__MODULE__{}, name: name)
  end

  @doc """
  This function is called once by an `EventTracker.Supervisor` to kick off the initial `EventTracker`s.
  """
  @spec begin(et_supervisor :: pid() | atom(), manager :: pid() | atom()) :: :ok | :already_began
  def begin(et_supervisor, manager \\ __MODULE__) do
    GenServer.cast(manager, {:begin, et_supervisor})
  end

  ### Impl

  @impl GenServer
  def init(init_arg) do
    Process.send_after(self(), :gather_reports, @report_interval_ms)
    {:ok, init_arg}
  end

  @impl GenServer
  def handle_call({:begin, _supervisor}, _from, %Manager{began?: true} = state) do
    {:reply, :already_began, state}
  end

  @impl GenServer
  def handle_cast({:begin, supervisor}, %Manager{} = state) do
    num_ets = String.to_integer(System.get_env("NUM_EVENT_TRACKERS") || "2")

    _event_trackers = spawn_ets(supervisor, num_ets)

    {:noreply, %Manager{state | supervisor: supervisor, began?: true}}
  end

  @impl GenServer
  def handle_info(:gather_reports, %Manager{supervisor: supervisor} = state) do
    reports =
      for {:undefined, pid, _, _} when is_pid(pid) <- DynamicSupervisor.which_children(supervisor) do
        EventTracker.pop_report(pid)
      end

    failing_reports = Report.evaluate_many(reports, @margins_of_error)

    Enum.each(failing_reports, fn {%Report{} = report, event, failed_by} ->
      Logger.warning(ess_conn_restart_message(report, event, failed_by, report.service_id))
      DynamicSupervisor.terminate_child(supervisor, report.event_tracker_pid)
      spawn_ets(supervisor, 1)
    end)

    Process.send_after(self(), :gather_reports, @report_interval_ms)

    {:noreply, state}
  end

  defp spawn_ets(supervisor, num_to_spawn) when num_to_spawn >= 0,
    do: spawn_ets(supervisor, num_to_spawn, [])

  defp spawn_ets(_supervisor, 0, et_list), do: et_list

  defp spawn_ets(supervisor, num_to_spawn, et_list) do
    new_et_list =
      case DynamicSupervisor.start_child(supervisor, {EventTracker, []}) do
        {:ok, et} ->
          [et | et_list]

        {:ok, et, _info} ->
          [et | et_list]

        :ignore ->
          et_list
      end

    spawn_ets(supervisor, num_to_spawn - 1, new_et_list)
  end

  defp ess_conn_restart_message(%Report{} = failing_report, event, failed_by, service_id) do
    redacted_sid = String.first(service_id) <> ".........." <> String.slice(service_id, -2..-1)

    """
    Terminating #{inspect(failing_report.event_tracker_pid)}
    Event count for #{event} failed by #{failed_by} with SID: #{redacted_sid}
    """
  end
end
