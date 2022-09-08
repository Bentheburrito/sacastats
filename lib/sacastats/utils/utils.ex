defmodule SacaStats.Utils do
  @moduledoc """
  Generic utility functions
  """

  def maybe_to_int(value, default \\ :use_value)

  def maybe_to_int(value, _default) when is_integer(value), do: value

  def maybe_to_int(value, default) when is_binary(value) do
    case Integer.parse(value) do
      {int_value, _rest} -> int_value
      :error -> if default == :use_value, do: value, else: default
    end
  end

  def maybe_to_int(value, default) do
    if default == :use_value, do: value, else: default
  end

  @doc """
  Safely divides numerator by denominator, and returns the result multiplied by 100 to yield a percentage. Automatically
  rounds to 2 decimal points and minimizes the result to `100`. See the `Options` for more details

  ### Options
  - `:to_round` - the number of decimal points to round to. Defaults to `2`
  - `:max_at` - If the resulting percentage is greater than `:max_at`, this function returns `:max_at` instead.
  Defaults to 100. Can take `:infinity`

  #### Examples:

      iex> to_percent(1, 2)
      ...> 50

      iex> to_percent(24, 33, to_round: 5)
      ...> 0.72727

      # exclude the denominator if you already have a percentage
      iex> to_percent(110, max_at: 99)
      ...> 99
  """
  def to_percent(numerator, denominator \\ 1, opts \\ [])
  # temp clause until weapon stats have changeset casting to ensure we only pass #s to this fn
  def to_percent(num, den, _) when is_nil(num) or is_nil(den) do
    0
  end

  def to_percent(numerator, denominator, opts) do
    to_round = Keyword.get(opts, :to_round, 2)
    max_at = Keyword.get(opts, :max_at, 100)

    (100 * safe_divide(numerator, denominator))
    |> Float.round(to_round)
    |> min(max_at)
  end

  @doc """
  Divide numerator by denominator with optional rounding, unless denominator is 0, in which case numerator is simply
  rounded according to `to_round`.
  """
  def safe_divide(numerator, denominator, to_round \\ :no_rounding)

  def safe_divide(numerator, denominator, :no_rounding) do
    numerator / ((denominator == 0 && 1) || denominator)
  end

  def safe_divide(numerator, denominator, to_round) do
    Float.round(safe_divide(numerator, denominator), to_round)
  end

  def bool_to_int(expression), do: (expression && 1) || 0

  # via https://dorgan.netlify.app/posts/2021/04/the_elixir_ast_typedstruct/
  defmacro typedstruct(do: ast) do
    fields_ast =
      case ast do
        {:__block__, [], fields} -> fields
        field -> [field]
      end

    fields_data = Enum.map(fields_ast, &get_field_data/1)

    enforced_fields =
      for field <- fields_data, field.enforced? do
        field.name
      end

    typespecs =
      Enum.map(fields_data, fn
        %{name: name, typespec: typespec, enforced?: true} ->
          {name, typespec}

        %{name: name, typespec: typespec} ->
          {
            name,
            {:|, [], [typespec, nil]}
          }
      end)

    fields =
      for %{name: name, default: default} <- fields_data do
        {name, default}
      end

    quote location: :keep do
      @type t :: %__MODULE__{unquote_splicing(typespecs)}
      @enforce_keys unquote(enforced_fields)
      defstruct unquote(fields)
    end
  end

  defp get_field_data({:field, _meta, [name, typespec]}) do
    get_field_data({:field, [], [name, typespec, []]})
  end

  defp get_field_data({:field, _meta, [name, typespec, opts]}) do
    default = Keyword.get(opts, :default)
    enforced? = Keyword.get(opts, :enforced?, false)

    %{
      name: name,
      typespec: typespec,
      default: default,
      enforced?: enforced?
    }
  end

  def get_rank_string(battle_rank, prestige) do
    if maybe_to_int(prestige, 0) > 0 do
      "ASP " <> prestige <> " BR " <> battle_rank
    else
      "BR " <> battle_rank
    end
  end
end
