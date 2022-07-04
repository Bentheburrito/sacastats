defmodule SacaStats.EventTracker.ReportTest do
  use ExUnit.Case

  alias SacaStats.EventTracker.Report

  @margins_of_error %{
    event_counts: %{
      "GainExperience" => 10,
      "VehicleDestroy" => 2
    }
  }

  describe "evaluate_two/3" do
    test "returns `:all_valid` for two acceptable reports" do
      r1 = %Report{event_counts: %{"GainExperience" => 20}}
      r2 = %Report{event_counts: %{"GainExperience" => 21}}

      assert :all_valid = Report.evaluate_two(r1, r2, @margins_of_error)

      r2 = %Report{event_counts: %{"GainExperience" => 11, "VehicleDestroy" => 1}}

      assert :all_valid = Report.evaluate_two(r1, r2, @margins_of_error)
    end

    test "returns `{^r1, _, _}` when the first report fails" do
      r1 = %Report{event_counts: %{"GainExperience" => 20}}
      r2 = %Report{event_counts: %{"GainExperience" => 32}}

      assert {^r1, "GainExperience", 2} = Report.evaluate_two(r1, r2, @margins_of_error)

      r2 = %Report{event_counts: %{"GainExperience" => 20, "VehicleDestroy" => 3}}

      assert {^r1, "VehicleDestroy", 1} = Report.evaluate_two(r1, r2, @margins_of_error)
    end

    test "returns `{^r2, _, _}` when the second report fails" do
      r1 = %Report{event_counts: %{"GainExperience" => 20}}
      r2 = %Report{event_counts: %{"GainExperience" => 2}}

      assert {^r2, "GainExperience", 8} = Report.evaluate_two(r1, r2, @margins_of_error)

      r1 = %Report{event_counts: %{"GainExperience" => 2, "VehicleDestroy" => 5}}

      assert {^r2, "VehicleDestroy", 3} = Report.evaluate_two(r1, r2, @margins_of_error)
    end
  end

  describe "evaluate_many/2" do
    test "returns an empty list if either no or one report is passed" do
      assert [] = Report.evaluate_many([], @margins_of_error)
      assert [] = Report.evaluate_many([%Report{}], @margins_of_error)
    end

    test "returns an empty list for a list of acceptable reports" do
      reports = [
        %Report{event_counts: %{"GainExperience" => 20, "VehicleDestroy" => 2}},
        %Report{event_counts: %{"GainExperience" => 25, "VehicleDestroy" => 1}},
        %Report{event_counts: %{"GainExperience" => 30}}
      ]

      assert [] = Report.evaluate_many(reports, @margins_of_error)
    end

    test "returns a list of the two failing reports out of a list of five reports" do
      [fr1, fr2] =
        failing_reports = [
          %Report{event_counts: %{"GainExperience" => 30, "VehicleDestroy" => 1}},
          %Report{event_counts: %{"GainExperience" => 15}}
        ]

      reports =
        [
          %Report{event_counts: %{"GainExperience" => 20, "VehicleDestroy" => 4}},
          %Report{event_counts: %{"GainExperience" => 25, "VehicleDestroy" => 3}},
          %Report{event_counts: %{"GainExperience" => 30, "VehicleDestroy" => 2}}
        ] ++ failing_reports

      assert [
               {^fr1, "VehicleDestroy", 1},
               {^fr2, "GainExperience", 5}
             ] = Report.evaluate_many(reports, @margins_of_error)
    end
  end

  describe "get_failing_data/3" do
    @margin 2
    test "returns `:all_valid` for two acceptable event counts" do
      counts_1 = 20
      counts_2 = 21

      assert :all_valid = Report.get_failing_data(counts_1, counts_2, @margin)

      counts_2 = 19

      assert :all_valid = Report.get_failing_data(counts_1, counts_2, @margin)
    end

    test "returns `{:first, _}` when the first report fails" do
      counts_1 = 20
      counts_2 = 32

      assert {:first, 10} = Report.get_failing_data(counts_1, counts_2, @margin)

      counts_2 = 23

      assert {:first, 1} = Report.get_failing_data(counts_1, counts_2, @margin)
    end

    test "returns `{^r2, _, _}` when the second report fails" do
      counts_1 = 10
      counts_2 = 0

      assert {:second, 8} = Report.get_failing_data(counts_1, counts_2, @margin)

      counts_1 = 5

      assert {:second, 3} = Report.get_failing_data(counts_1, counts_2, @margin)
    end
  end
end
