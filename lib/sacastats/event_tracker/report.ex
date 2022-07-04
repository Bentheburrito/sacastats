defmodule SacaStats.EventTracker.Report do
  @moduledoc """
  A struct to hold an `EventTracker` report for an `EventTracker.Manager` to evaluate based on the functions in this
  module.
  """
  alias SacaStats.EventTracker.Report

  defstruct event_counts: %{}, event_tracker_pid: nil, service_id: ""

  @type t() :: %__MODULE__{
          event_counts: map(),
          event_tracker_pid: pid() | nil
        }

  @spec evaluate_two(r1 :: t(), r2 :: t(), margins_of_error :: map()) ::
          :all_valid | {:first, integer()} | {:second, integer()}
  def evaluate_two(%Report{} = r1, %Report{} = r2, margins_of_error) do
    %{event_counts: event_counts_moe} = margins_of_error

    evaluate_event_counts(r1, r2, :all_valid, event_counts_moe)
  end

  @spec evaluate_many(reports :: [t()], margins_of_error :: map()) :: [{t(), String.t(), any()}]
  def evaluate_many(reports, _moe) when length(reports) <= 1, do: []

  def evaluate_many(reports, margins_of_error) do
    %{event_counts: event_counts_moe} = margins_of_error

    max_values = get_max_values_of(reports, margins_of_error)

    reports
    |> Enum.reduce([], fn %Report{} = report, failing_reports ->
      case evaluate_event_counts(report, max_values, false, event_counts_moe) do
        {^report, _, _} = failed_report -> [failed_report | failing_reports]
        _ -> failing_reports
      end
    end)
    # Reverse the list so that the order is consistent with the input `reports`.
    # This is mainly to make it easily testable.
    |> Enum.reverse()
  end

  def get_failing_data(first_count, second_count, margin) do
    diff = first_count - second_count

    cond do
      # if the difference between first and second counts is greater than the error margin, the second report is losing
      # too many events, and fails by diff - margin events.
      diff > margin -> {:second, diff - margin}
      # if the opposite is true, the first report has failed.
      diff < -margin -> {:first, -diff - margin}
      # otherwise, both streams are reporting a sufficiently consistent number of events.
      :else -> :all_valid
    end
  end

  defp evaluate_event_counts(
         report1,
         report2,
         default_acc,
         event_counts_margins_of_error
       ) do
    Enum.reduce_while(event_counts_margins_of_error, default_acc, fn {event, margin}, acc ->
      r1_count = Map.get(report1.event_counts, event, 0)
      r2_count = Map.get(report2.event_counts, event, 0)

      case get_failing_data(r1_count, r2_count, margin) do
        :all_valid -> {:cont, acc}
        {:first, failed_by} -> {:halt, {report1, event, failed_by}}
        {:second, failed_by} -> {:halt, {report2, event, failed_by}}
      end
    end)
  end

  defp get_max_values_of(reports, margins_of_error) do
    %{event_counts: event_counts_moe} = margins_of_error

    max_event_counts =
      Enum.reduce(event_counts_moe, %{}, fn {event, _margin}, max_values ->
        max_val =
          reports
          |> Stream.map(&Map.get(&1.event_counts, event, 0))
          |> Enum.max()

        Map.put(max_values, event, max_val)
      end)

    %{event_counts: max_event_counts}
  end
end
