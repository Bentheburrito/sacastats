defmodule SacaStats.Conversions do
  @moduledoc """
  Context module for converting numbers to other numbers and labels.
  """

  def medal_code_by_kill_count(kill_count) do
    cond do
      kill_count >= 1160 -> 3068
      kill_count >= 160 -> 3075
      kill_count >= 60 -> 3079
      kill_count >= 10 -> 3072
      :else -> -1
    end
  end

  def medal_name_by_kill_count(kill_count) do
    cond do
      kill_count >= 1160 -> "Auraxium"
      kill_count >= 160 -> "Gold"
      kill_count >= 60 -> "Silver"
      kill_count >= 10 -> "Bronze"
      :else -> "none"
    end
  end

  def kills_to_next_medal(kill_count) do
    cond do
      kill_count >= 1160 -> "N/A"
      kill_count >= 160 -> 1160 - kill_count
      kill_count >= 60 -> 160 - kill_count
      kill_count >= 10 -> 60 - kill_count
      :else -> 10 - kill_count
    end
  end

  def score_to_cert_count(nil), do: 0

  def score_to_cert_count(score) do
    score
    |> SacaStats.Utils.maybe_to_int(0)
    |> div(250)
  end
end
