defmodule SacaStatsWeb.CharacterView do
  use SacaStatsWeb, :view

  require Logger

  def pretty_session_summary(assigns, session) do
    login_time = prettify_timestamp(session.login.timestamp)
    logout_time = prettify_timestamp(session.logout.timestamp)
    session_duration = prettify_duration(session.login.timestamp, session.logout.timestamp)

    ~H"""
    <div class="poll-item text-dark">
      <%= login_time %> → <%= logout_time %>
      <br>
      <%= session_duration %>
    </div>
    """
  end

  def prettify_timestamp(:current_session), do: "Current Session"

  def prettify_timestamp(timestamp) do
    dt = DateTime.from_unix!(timestamp)
    padded_minutes = dt.minute |> Integer.to_string() |> String.pad_leading(2, "0")
    padded_seconds = dt.second |> Integer.to_string() |> String.pad_leading(2, "0")
    "#{dt.day}/#{dt.month}/#{dt.year} #{dt.hour}:#{padded_minutes}:#{padded_seconds}"
  end

  def prettify_duration(start_ts, :current_session), do: prettify_duration(start_ts, System.os_time(:second))

  def prettify_duration(start_ts, end_ts) do
    total_seconds = end_ts - start_ts
    seconds = rem(total_seconds, 60)
    minutes = rem(div(total_seconds, 60), 60)
    hours = rem(div(total_seconds, 60 * 60), 60)

    [{hours, "hours"}, {minutes, "minutes"}, {seconds, "seconds"}]
    |> Stream.filter(fn {duration, _unit} -> duration > 0 end)
    |> Stream.map(fn {duration, unit} -> "#{duration} #{unit}" end)
    |> Enum.join(" ")
  end
end
