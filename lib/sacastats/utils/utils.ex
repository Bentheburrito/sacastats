defmodule SacaStats.Utils do
  @moduledoc """
  Generic utility functions
  """

  def maybe_to_int(value, default \\ 0)

  def maybe_to_int(value, _default) when is_integer(value), do: value

  def maybe_to_int(value, default) when value in [nil, ""], do: default

  def maybe_to_int(value, default) when is_binary(value) do
    case Integer.parse(value) do
      {parsed_int, _rest} -> parsed_int
      :error -> default
    end
  end

  def safe_divide(numerator, denominator, to_round \\ :no_rounding)

  def safe_divide(numerator, denominator, :no_rounding) do
    numerator / (denominator == 0 && 1 || denominator)
  end

  def safe_divide(numerator, denominator, to_round) do
    Float.round(safe_divide(numerator, denominator), to_round)
  end

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
        %{name: name, typespec: typespec, enforced?: true} -> {name, typespec}
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
end
