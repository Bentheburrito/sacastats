defmodule SacaStats.Utils do
  def maybe_to_int(value, default \\ 0)

  def maybe_to_int(value, _default) when is_integer(value), do: value

  def maybe_to_int(value, default) when value in [nil, ""], do: default

  def maybe_to_int(value, default) when is_binary(value) do
    case Integer.parse(value) do
      {parsed_int, _rest} -> parsed_int
      :error -> default
    end
  end
end
