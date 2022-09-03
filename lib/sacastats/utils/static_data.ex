defmodule SacaStats.Utils.StaticData do
  @moduledoc """
  Utility/helper functions for static data transformation.
  """

  alias SacaStats.Utils

  def load_static_file(path) do
    path
    |> File.read!()
    |> Jason.decode!()
    |> Enum.map(fn {key_str, val} -> {String.to_integer(key_str), val} end)
    |> Map.new(fn {str_key, value} -> {Utils.maybe_to_int(str_key), value} end)
  end
end
