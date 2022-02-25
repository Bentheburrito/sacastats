defmodule SacaStats.Utils.StaticData do
  @moduledoc """
  Utility/helper functions for static data transformation.
  """

  def load_static_file(path) do
    path
    |> File.read!()
    |> Jason.decode!()
    |> Enum.map(fn {key_str, val} -> {String.to_integer(key_str), val} end)
    |> Enum.into(%{})
  end
end
