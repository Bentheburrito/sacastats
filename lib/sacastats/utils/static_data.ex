defmodule SacaStats.Utils.StaticData do
  def load_static_file(path) do
    path
    |> File.read!()
    |> Jason.decode!()
    |> Enum.map(fn {key_str, val} -> {String.to_integer(key_str), val} end)
    |> Enum.into(%{})
  end

  def maybe_to_int(value) when is_integer(value), do: value

  def maybe_to_int(value, default \\ :use_value) when is_binary(value) do
    case Integer.parse(value) do
      {int_value, _rest} -> int_value
      :error -> if default == :use_value, do: value, else: default
    end
  end
end
