defmodule Xema.Validator do
  @moduledoc false

  use Xema.Format

  @type result :: :ok | {:error, map}

  @types [:boolean, :atom, :string, :integer, :float, :number, :list, :map, nil]

  @spec validate(Xema.t() | Xema.Schema.t(), any) :: result
  def validate(schema, value, opts \\ [])

  def validate(%{content: schema}, value, opts) do
    validate(schema, value, opts)
  end

  def validate(%{type: true}, _value, _opts), do: :ok

  def validate(%{type: false}, _value, _opts), do: {:error, %{type: false}}

  def validate(schema, value, opts) do
    # IO.inspect opts, label: "opts"
    opts = Keyword.put(opts, :root, schema)

    case schema.type do
      list when is_list(list) ->
        with {:ok, type} <- types(schema, value),
             :ok <- validate(%{schema | type: type}, value, opts),
             do: :ok

      :any ->
        with type <- get_type(value),
             :ok <- validate(:default, schema, value, opts),
             :ok <- validate(type, schema, value, opts),
             do: :ok

      :string ->
        with :ok <- type(schema, value),
             :ok <- validate(:default, schema, value, opts),
             :ok <- validate(:string, schema, value, opts),
             do: :ok

      :list ->
        with :ok <- type(schema, value),
             :ok <- validate(:list, schema, value, opts),
             do: :ok

      :map ->
        with :ok <- type(schema, value),
             :ok <- validate(:map, schema, value, opts),
             do: :ok

      type when is_atom(type) ->
        validate(type, schema, value, opts)
    end
  end

  #
  # Private validate function
  #

  defp validate(:default, schema, value, _opts) do
    with :ok <- enum(schema, value),
         :ok <- do_not(schema, value),
         :ok <- all_of(schema, value),
         :ok <- any_of(schema, value),
         :ok <- one_of(schema, value),
         do: :ok
  end

  defp validate(:string, schema, value, _opts) do
    with length <- String.length(value),
         :ok <- min_length(schema, length, value),
         :ok <- max_length(schema, length, value),
         :ok <- pattern(schema, value),
         :ok <- format(schema, value),
         :ok <- enum(schema, value),
         do: :ok
  end

  defp validate(nil, _schema, nil, _opts), do: :ok

  defp validate(nil, schema, value, _opts),
    do: {:error, %{value: value, type: schema.as}}

  defp validate(:list, schema, value, _opts) do
    with :ok <- min_items(schema, value),
         :ok <- max_items(schema, value),
         :ok <- items(schema, value),
         :ok <- unique(schema, value),
         do: :ok
  end

  defp validate(:map, schema, value, _opts) do
    with :ok <- size(schema, value),
         :ok <- keys(schema, value),
         :ok <- required(schema, value),
         :ok <- dependencies(schema, value),
         {:ok, patts_rest} <- patterns(schema, value),
         {:ok, props_rest} <- properties(schema, value),
         value <- intersection(props_rest, patts_rest),
         :ok <- additionals(schema, value),
         do: :ok
  end

  defp validate(:boolean, schema, value, _opts) do
    case is_boolean(value) do
      true -> :ok
      false -> {:error, %{value: value, type: schema.as}}
    end
  end

  defp validate(:integer, schema, value, opts),
    do: validate(:number, schema, value, opts)

  defp validate(:float, schema, value, opts),
    do: validate(:number, schema, value, opts)

  defp validate(:number, schema, value, opts) do
    with :ok <- type(schema, value),
         :ok <- minimum(schema, value),
         :ok <- maximum(schema, value),
         :ok <- exclusive_maximum(schema, value),
         :ok <- exclusive_minimum(schema, value),
         :ok <- multiple_of(schema, value),
         :ok <- validate(:default, schema, value, opts),
         do: :ok
  end

  defp validate(:atom, _, _, _), do: :ok

  #
  # Schema type handling
  #

  defp get_type(value),
    do: Enum.find(@types, fn type -> is_type?(type, value) end)

  @spec type(Xema.Schema.t() | atom, any) :: result
  defp type(%{type: type} = schema, value) do
    case is_type?(type, value) do
      true -> :ok
      false -> {:error, %{type: schema.as, value: value}}
    end
  end

  @spec is_type?(atom, any) :: boolean
  defp is_type?(:any, _value), do: true
  defp is_type?(:atom, value), do: is_atom(value)
  defp is_type?(:string, value), do: is_binary(value)
  defp is_type?(:number, value), do: is_number(value)
  defp is_type?(:integer, value), do: is_integer(value)
  defp is_type?(:float, value), do: is_float(value)
  defp is_type?(:map, value), do: is_map(value)
  defp is_type?(:list, value), do: is_list(value)
  defp is_type?(:boolean, value), do: is_boolean(value)
  defp is_type?(nil, nil), do: true
  defp is_type?(_, _), do: false

  @spec types([atom], any) :: {:ok, atom} | {:error, map}
  defp types(%{type: list} = schema, value) do
    case Enum.find(list, :not_found, fn type -> is_type?(type, value) end) do
      :not_found -> {:error, %{type: schema.as, value: value}}
      found -> {:ok, found}
    end
  end

  #
  # Validators
  #

  @spec enum(Xema.Schema.t(), any) :: result
  defp enum(%{enum: nil}, _element), do: :ok

  defp enum(%{enum: enum}, value) do
    case Enum.member?(enum, value) do
      true -> :ok
      false -> {:error, %{enum: enum, value: value}}
    end
  end

  @spec do_not(Xema.Schema.t(), any) :: result
  defp do_not(%{not: nil}, _value), do: :ok

  defp do_not(%{not: schema}, value) do
    case validate(schema, value) do
      :ok -> {:error, :not}
      _ -> :ok
    end
  end

  @spec all_of(Xema.Schema.t(), any) :: result
  defp all_of(%{all_of: nil}, _value), do: :ok

  defp all_of(%{all_of: schemas}, value) do
    case do_all_of(schemas, value) do
      true -> :ok
      false -> {:error, :all_of}
    end
  end

  @spec do_all_of(list, any) :: boolean
  defp do_all_of(schemas, value),
    do: Enum.all?(schemas, fn schema -> validate(schema, value) == :ok end)

  @spec any_of(Xema.Schema.t(), any) :: result
  defp any_of(%{any_of: nil}, _value), do: :ok

  defp any_of(%{any_of: schemas}, value) do
    case do_any_of(schemas, value) do
      true -> :ok
      false -> {:error, :any_of}
    end
  end

  @spec do_any_of(list, any) :: boolean
  defp do_any_of(schemas, value),
    do: Enum.any?(schemas, fn schema -> validate(schema, value) == :ok end)

  @spec one_of(Xema.Schema.t(), any) :: result
  defp one_of(%{one_of: nil}, _value), do: :ok

  defp one_of(%{one_of: schemas}, value) do
    case do_one_of(schemas, value) == 1 do
      true -> :ok
      false -> {:error, :one_of}
    end
  end

  @spec do_one_of(list, any) :: integer
  defp do_one_of(schemas, value) do
    schemas
    |> Enum.filter(fn schema ->
      case validate(schema, value) do
        :ok -> true
        {:error, _} -> false
      end
    end)
    |> Enum.count()
  end

  @spec exclusive_maximum(Xema.Schema.t(), any) :: result
  defp exclusive_maximum(%{exclusive_maximum: nil}, _value), do: :ok

  defp exclusive_maximum(%{exclusive_maximum: max}, _value)
       when is_boolean(max),
       do: :ok

  defp exclusive_maximum(%{exclusive_maximum: max}, value)
       when value < max,
       do: :ok

  defp exclusive_maximum(%{exclusive_maximum: max}, value),
    do: {:error, %{exclusive_maximum: max, value: value}}

  @spec exclusive_minimum(Xema.Schema.t(), any) :: result
  defp exclusive_minimum(%{exclusive_minimum: nil}, _value), do: :ok

  defp exclusive_minimum(%{exclusive_minimum: min}, _value)
       when is_boolean(min),
       do: :ok

  defp exclusive_minimum(%{exclusive_minimum: min}, value)
       when value > min,
       do: :ok

  defp exclusive_minimum(%{exclusive_minimum: min}, value),
    do: {:error, %{value: value, exclusive_minimum: min}}

  @spec minimum(Xema.Schema.t(), any) :: result
  defp minimum(%{minimum: nil}, _value), do: :ok

  defp minimum(
         %{minimum: minimum, exclusive_minimum: exclusive_minimum},
         value
       )
       when is_number(value),
       do: minimum(minimum, exclusive_minimum, value)

  defp minimum(_, _), do: :ok

  @spec minimum(number, boolean, number) :: result
  defp minimum(minimum, _exclusive, value) when value > minimum, do: :ok
  defp minimum(minimum, nil, value) when value == minimum, do: :ok
  defp minimum(minimum, false, value) when value == minimum, do: :ok

  defp minimum(minimum, nil, value),
    do: {:error, %{value: value, minimum: minimum}}

  defp minimum(minimum, exclusive, value),
    do:
      {:error, %{value: value, minimum: minimum, exclusive_minimum: exclusive}}

  @spec maximum(Xema.Schema.t(), any) :: result
  defp maximum(%{maximum: nil}, _value), do: :ok

  defp maximum(
         %{maximum: maximum, exclusive_maximum: exclusive_maximum},
         value
       ),
       do: maximum(maximum, exclusive_maximum, value)

  @spec maximum(number, boolean, number) :: result
  defp maximum(maximum, _exclusive, value) when value < maximum, do: :ok
  defp maximum(maximum, nil, value) when value == maximum, do: :ok
  defp maximum(maximum, false, value) when value == maximum, do: :ok

  defp maximum(maximum, nil, value),
    do: {:error, %{value: value, maximum: maximum}}

  defp maximum(maximum, exclusive, value),
    do:
      {:error, %{value: value, maximum: maximum, exclusive_maximum: exclusive}}

  @spec multiple_of(Xema.Schema.t(), number) :: result
  defp multiple_of(%{multiple_of: nil} = _keywords, _value), do: :ok

  defp multiple_of(%{multiple_of: multiple_of}, value) when is_number(value) do
    x = value / multiple_of

    case x - Float.floor(x) do
      0.0 -> :ok
      _ -> {:error, %{value: value, multiple_of: multiple_of}}
    end
  end

  defp multiple_of(_, _), do: :ok

  @spec min_length(Xema.Schema.t(), integer, String.t()) :: result
  defp min_length(%{min_length: nil}, _, _), do: :ok
  defp min_length(%{min_length: min}, len, _) when len >= min, do: :ok

  defp min_length(%{min_length: min}, _, value),
    do: {:error, %{value: value, min_length: min}}

  @spec max_length(Xema.Schema.t(), integer, String.t()) :: result
  defp max_length(%{max_length: nil}, _, _), do: :ok
  defp max_length(%{max_length: max}, len, _) when len <= max, do: :ok

  defp max_length(%{max_length: max}, _, value),
    do: {:error, %{value: value, max_length: max}}

  @spec pattern(Xema.Schema.t(), String.t()) :: result
  defp pattern(%{pattern: nil}, _string), do: :ok

  defp pattern(%{pattern: pattern}, string) do
    case Regex.match?(pattern, string) do
      true -> :ok
      false -> {:error, %{value: string, pattern: pattern}}
    end
  end

  @spec min_items(Xema.Schema.t(), list) :: result
  defp min_items(%{min_items: nil}, _list), do: :ok

  defp min_items(%{min_items: min}, list) when length(list) >= min do
    :ok
  end

  defp min_items(%{min_items: min}, list),
    do: {:error, %{value: list, min_items: min}}

  @spec max_items(Xema.Schema.t(), list) :: result
  defp max_items(%{max_items: nil}, _list), do: :ok

  defp max_items(%{max_items: max}, list) when length(list) <= max do
    :ok
  end

  defp max_items(%{max_items: max}, list),
    do: {:error, %{value: list, max_items: max}}

  @spec unique(Xema.Schema.t(), list) :: result
  defp unique(%{unique_items: nil}, _list), do: :ok

  defp unique(%{unique_items: true}, list) do
    case is_unique?(list) do
      true -> :ok
      false -> {:error, %{value: list, unique_items: true}}
    end
  end

  @spec is_unique?(list, map) :: boolean
  def is_unique?(list, set \\ %{})
  def is_unique?([], _), do: true

  def is_unique?([h | t], set) do
    case set do
      %{^h => true} -> false
      _ -> is_unique?(t, Map.put(set, h, true))
    end
  end

  @spec items(Xema.Schema.t(), list) :: result
  defp items(%{items: nil}, _list), do: :ok

  defp items(%{items: items, additional_items: additional_items}, list)
       when is_list(items),
       do: items_tuple(items, update_nil(additional_items, true), list, 0, [])

  defp items(%{items: items}, list), do: items_list(items, list, 0, [])

  @spec items_list(Xema.Schema.t(), list, integer, list) :: result
  defp items_list(_schema, [], _at, []), do: :ok
  defp items_list(_schema, [], _at, errors), do: {:error, Enum.reverse(errors)}

  defp items_list(schema, [item | list], at, errors) do
    case validate(schema, item) do
      :ok ->
        items_list(schema, list, at + 1, errors)

      {:error, reason} ->
        items_list(schema, list, at + 1, [{at, reason} | errors])
    end
  end

  @spec items_tuple(list, nil | boolean | Xema.Schema.t(), list, integer, list) ::
          result
  defp items_tuple(_schemas, _additonal_items, [], _at, []), do: :ok

  defp items_tuple(_schemas, _additonal_items, [], _at, errors),
    do: {:error, Enum.reverse(errors)}

  defp items_tuple([], false, [_ | list], at, errors),
    do:
      items_tuple([], false, list, at + 1, [
        {at, %{additional_items: false}} | errors
      ])

  defp items_tuple([], true, _list, _at, []), do: :ok

  defp items_tuple([], true, _list, _at, errors),
    do: {:error, Enum.reverse(errors)}

  defp items_tuple([], schema, [item | list], at, errors) do
    case validate(schema, item) do
      :ok ->
        items_tuple([], schema, list, at + 1, errors)

      {:error, reason} ->
        items_tuple([], schema, list, at + 1, [{at, reason} | errors])
    end
  end

  defp items_tuple(
         [schema | schemas],
         additional_items,
         [item | list],
         at,
         errors
       ) do
    case validate(schema, item) do
      :ok ->
        items_tuple(schemas, additional_items, list, at + 1, errors)

      {:error, reason} ->
        items_tuple(schemas, additional_items, list, at + 1, [
          {at, reason} | errors
        ])
    end
  end

  @spec keys(Xema.Schema.t(), any) :: result
  defp keys(%{keys: nil}, _value), do: :ok

  defp keys(%{keys: :atoms}, map) do
    case map |> Map.keys() |> Enum.all?(&is_atom/1) do
      true -> :ok
      false -> {:error, %{keys: :atoms}}
    end
  end

  defp keys(%{keys: :strings}, map) do
    case map |> Map.keys() |> Enum.all?(&is_binary/1) do
      true -> :ok
      false -> {:error, %{keys: :strings}}
    end
  end

  @spec properties(Xema.Schema.t(), map) :: result
  defp properties(%{properties: nil}, map), do: {:ok, map}

  defp properties(%{properties: props}, map) do
    do_properties(Map.to_list(props), map, %{})
  end

  @spec do_properties(list, map, map) :: result
  defp do_properties([], map, errors) when errors == %{}, do: {:ok, map}

  defp do_properties([], _map, errors), do: {:error, %{properties: errors}}

  defp do_properties([{prop, schema} | props], map, errors) do
    with true <- has_key?(map, prop),
         {:ok, value} <- get_value(map, prop),
         :ok <- validate(schema, value) do
      case has_key?(props, prop) do
        true -> do_properties(props, map, errors)
        false -> do_properties(props, delete_property(map, prop), errors)
      end
    else
      # The property is not in the map.
      false ->
        do_properties(props, delete_property(map, prop), errors)

      {:error, reason} ->
        do_properties(
          props,
          Map.delete(map, prop),
          Map.put(errors, get_key(map, prop), reason)
        )
    end
  end

  @spec delete_property(map, String.t() | atom) :: map
  defp delete_property(map, prop) when is_map(map) and is_atom(prop) do
    case Map.has_key?(map, prop) do
      true -> Map.delete(map, prop)
      false -> Map.delete(map, Atom.to_string(prop))
    end
  end

  defp delete_property(map, prop) when is_map(map) and is_binary(prop) do
    case Map.has_key?(map, prop) do
      true -> Map.delete(map, prop)
      false -> Map.delete(map, String.to_existing_atom(prop))
    end
  end

  @spec required(Xema.Schema.t(), map) :: result
  defp required(%{required: nil}, _map), do: :ok

  defp required(%{required: required}, map) do
    case Enum.filter(required, fn key -> !has_key?(map, key) end) do
      [] ->
        :ok

      missing ->
        {
          :error,
          %{required: missing}
          # Enum.into(missing, %{}, fn key -> {:required, key} end)
        }
    end
  end

  # TODO: function for strict mode
  # defp required(%{required: required}, map) do
  #   props = map |> Map.keys() |> MapSet.new()
  #
  #   case MapSet.subset?(required, props) do
  #     true ->
  #       :ok
  #
  #     false ->
  #       {
  #         :error,
  #         required
  #         |> MapSet.difference(props)
  #         |> MapSet.to_list()
  #         |> Enum.into(%{}, fn x -> {x, :required} end)
  #       }
  #   end
  # end

  @spec size(Xema.Schema.t(), map) :: result
  defp size(%{min_properties: nil, max_properties: nil}, _map), do: :ok

  defp size(%{min_properties: min, max_properties: max}, map) do
    do_size(length(Map.keys(map)), min, max)
  end

  @spec do_size(number, number, number) :: result
  defp do_size(len, min, _max) when not is_nil(min) and len < min do
    {:error, %{min_properties: min}}
  end

  defp do_size(len, _min, max) when not is_nil(max) and len > max do
    {:error, %{max_properties: max}}
  end

  defp do_size(_len, _min, _max), do: :ok

  @spec patterns(Xema.Schema.t(), map) :: result
  defp patterns(%{pattern_properties: nil}, map), do: {:ok, map}

  defp patterns(%{pattern_properties: patterns}, map) do
    props =
      for {pattern, schema} <- Map.to_list(patterns),
          key <- Map.keys(map),
          key_match?(pattern, key),
          do: {key, schema}

    do_properties(props, map, %{})
  end

  @spec key_match?(Regex.t(), String.t() | atom) :: boolean
  defp key_match?(regex, atom) when is_atom(atom) do
    key_match?(regex, to_string(atom))
  end

  defp key_match?(regex, string), do: Regex.match?(regex, string)

  @spec additionals(Xema.Schema.t(), map) :: result
  defp additionals(%{additional_properties: false}, map) do
    case Map.equal?(map, %{}) do
      true ->
        :ok

      false ->
        {
          :error,
          %{
            properties:
              map
              |> Map.keys()
              |> Enum.into(%{}, fn x -> {x, %{additional_properties: false}} end)
          }
        }
    end
  end

  defp additionals(%{additional_properties: schema}, map)
       when is_map(schema) do
    result =
      Enum.reduce(map, %{}, fn {key, value}, acc ->
        case validate(schema, value) do
          :ok -> acc
          {:error, reason} -> Map.put(acc, key, reason)
        end
      end)

    case result == %{} do
      true -> :ok
      false -> {:error, result}
    end
  end

  defp additionals(_schema, _map), do: :ok

  @spec dependencies(Xema.Schema.t(), map) :: result
  defp dependencies(%{dependencies: nil}, _map), do: :ok

  defp dependencies(%{dependencies: dependencies}, map) do
    dependencies
    |> Map.to_list()
    |> Enum.filter(fn {key, _} -> has_key?(map, key) end)
    |> do_dependencies(map)
  end

  @spec do_dependencies(list, map) :: result
  defp do_dependencies([], _map), do: :ok

  defp do_dependencies([{key, list} | tail], map) when is_list(list) do
    with :ok <- do_dependencies_list(key, list, map) do
      do_dependencies(tail, map)
    end
  end

  # defp do_dependencies([{_key, true} | tail], map),
  #  do: do_dependencies(tail, map)
  #
  # defp do_dependencies([{key, false} | tail], map) do
  #  case Map.has_key?(map, key) do
  #    true -> {:error, %{dependencies: %{key => false}}}
  #    false -> do_dependencies(tail, map)
  #  end
  # end

  defp do_dependencies([{key, schema} | tail], map) do
    case validate(schema, map) do
      :ok ->
        do_dependencies(tail, map)

      {:error, reason} ->
        {:error, %{dependencies: %{key => reason}}}
    end
  end

  @spec do_dependencies_list(String.t() | atom, list, map) :: result
  defp do_dependencies_list(_key, [], _map), do: :ok

  defp do_dependencies_list(key, [dependency | dependencies], map) do
    case has_key?(map, dependency) do
      true ->
        do_dependencies_list(key, dependencies, map)

      false ->
        {:error, %{dependencies: %{key => dependency}}}
    end
  end

  # TODO: spec and doc
  defp format(%{format: nil}, _str), do: :ok

  defp format(%{format: fmt}, str) when Format.supports(fmt) do
    case Format.is?(fmt, str) do
      true -> :ok
      false -> {:error, %{format: fmt, value: str}}
    end
  end

  defp format(_, _str), do: :ok

  #
  # helper functions
  #

  @spec update_nil(any, any) :: any
  defp update_nil(nil, b), do: b
  defp update_nil(a, _b), do: a

  @spec get_value(map, String.t() | atom) :: any
  defp get_value(map, key) when is_atom(key) do
    do_get_value(map, to_string(key), key)
  end

  defp get_value(map, key) do
    do_get_value(map, key, String.to_atom(key))
  end

  defp do_get_value(map, key_string, key_atom) do
    case {Map.get(map, key_string), Map.get(map, key_atom)} do
      {nil, nil} ->
        {:ok, nil}

      {nil, value} ->
        {:ok, value}

      {value, nil} ->
        {:ok, value}

      _ ->
        {:error, :mixed_map}
    end
  end

  @spec get_key(map, String.t() | atom) :: atom | String.t()
  defp get_key(map, key) when is_atom(key) do
    if Map.has_key?(map, key), do: key, else: to_string(key)
  end

  defp get_key(map, key) do
    if Map.has_key?(map, key), do: key, else: String.to_existing_atom(key)
  end

  @spec has_key?(map, String.t() | atom) :: boolean
  defp has_key?(map, key) when is_map(map),
    do: Map.has_key?(map, key) || Map.has_key?(map, toggle_key(key))

  defp has_key?(list, key) when is_list(list) do
    Enum.any?(list, fn {k, _} -> k == key end)
  end

  @spec toggle_key(String.t() | atom) :: atom | String.t()
  defp toggle_key(key) when is_binary(key), do: to_existing_atom(key)

  defp toggle_key(key) when is_atom(key), do: Atom.to_string(key)

  @spec to_existing_atom(String.t()) :: atom | nil
  defp to_existing_atom(str) do
    String.to_existing_atom(str)
  catch
    _ -> nil
  end

  @spec intersection(map, map) :: map
  defp intersection(a, b),
    do:
      for(
        key <- Map.keys(a),
        true == Map.has_key?(b, key),
        into: %{},
        do: {key, Map.get(b, key)}
      )
end
