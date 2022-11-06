defmodule SacaStats.EventTracker.DeduperTest do
  use ExUnit.Case, async: true

  alias SacaStats.EventTracker.Deduper
  alias SacaStats.Events.{GainExperience, PlayerLogin, PlayerLogout, VehicleDestroy}

  setup %{} do
    me = self()

    opts = [
      emitter: &send(me, {:event_emitted, &1}),
      name: TestDeduper,
      emit_interval_ms: 100
    ]

    # Before each test, start a deduper whose emitter sends a message to the test process.
    start_supervised!({Deduper, opts})

    :ok
  end

  describe "SacaStats.EventTracker.Deduper" do
    test "will emit one copy of three duplicate events" do
      ge_event =
        GainExperience.changeset(%GainExperience{}, %{
          amount: 1,
          character_id: 1,
          experience_id: 1
        })

      Deduper.handle_event(TestDeduper, ge_event)
      Deduper.handle_event(TestDeduper, ge_event)
      Deduper.handle_event(TestDeduper, ge_event)

      assert_receive {:event_emitted, ^ge_event}, 5000
      refute_receive {:event_emitted, ^ge_event}, 200
    end

    test "will emit three events, where one event has many duplicates interspersed" do
      ge_event_1 =
        GainExperience.changeset(%GainExperience{}, %{
          amount: 1,
          character_id: 1,
          experience_id: 1
        })

      ge_event_2 =
        GainExperience.changeset(%GainExperience{}, %{
          amount: 2,
          character_id: 2,
          experience_id: 2
        })

      vd_event =
        VehicleDestroy.changeset(%VehicleDestroy{}, %{
          character_id: 1,
          timestamp: 1,
          attacker_character_id: 1
        })

      Deduper.handle_event(TestDeduper, vd_event)
      Deduper.handle_event(TestDeduper, ge_event_1)
      Deduper.handle_event(TestDeduper, vd_event)
      Deduper.handle_event(TestDeduper, ge_event_2)
      Deduper.handle_event(TestDeduper, vd_event)

      assert_receive {:event_emitted, ^ge_event_1}, 5000
      assert_receive {:event_emitted, ^vd_event}
      assert_receive {:event_emitted, ^ge_event_2}
      refute_receive {:event_emitted, ^vd_event}, 200
      refute_receive {:event_emitted, ^ge_event_1}
      refute_receive {:event_emitted, ^ge_event_2}
    end
  end

  describe "put_new_event/3" do
    @login_cs PlayerLogin.changeset(%PlayerLogin{}, %{
                character_id: 1234,
                timestamp: 1234,
                world_id: 1234
              })
    @logout_cs PlayerLogout.changeset(%PlayerLogout{}, %{
                 character_id: 4321,
                 timestamp: 4321,
                 world_id: 4321
               })
    @event_map %{"some_key" => @login_cs}

    test "will put a value under a new key in event_map when not buffering" do
      deduper_state =
        %Deduper{buffering?: false}
        |> Deduper.put_new_event("some_key", @login_cs)

      assert %Deduper{event_map: @event_map} = deduper_state

      deduper_state_2 =
        deduper_state
        |> Deduper.put_new_event("another_key", @logout_cs)

      assert %Deduper{
               event_map: %{"some_key" => @login_cs, "another_key" => @logout_cs}
             } = deduper_state_2
    end

    test "will not put a value under a key in the buffer when buffering and the key exists in the event_map" do
      deduper_state =
        %Deduper{buffering?: true, event_map: @event_map, buffer: %{}}
        |> Deduper.put_new_event("some_key", @login_cs)

      assert %Deduper{event_map: @event_map, buffer: %{}} = deduper_state

      buffer = %{"another_key" => @logout_cs}

      deduper_state_2 =
        %Deduper{buffering?: true, event_map: @event_map, buffer: buffer}
        |> Deduper.put_new_event("some_key", @login_cs)

      assert %Deduper{event_map: @event_map, buffer: ^buffer} = deduper_state_2
    end

    test "will put a value under a new key in the buffer when buffering and the key does not exist in the event_map" do
      deduper_state =
        %Deduper{buffering?: true, event_map: @event_map, buffer: %{}}
        |> Deduper.put_new_event("another_key", @logout_cs)

      target_buffer = %{"another_key" => @logout_cs}

      assert %Deduper{event_map: @event_map, buffer: ^target_buffer} = deduper_state
    end
  end
end
