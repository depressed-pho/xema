defmodule Xema do
  @moduledoc """
  A schema validator inspired by [JSON Schema](http://json-schema.org)
  """

  use Xema.Base

  alias Xema.Schema
  alias Xema.SchemaError
  alias Xema.SchemaValidator

  @keywords %Schema{} |> Map.keys() |> MapSet.new() |> MapSet.delete(:data)

  @doc """
  This function defines the schemas.

  The first argument sets the `type` of the schema. The second arguments
  contains the 'keywords' of the schema.

  ## Parameters

    - type: type of the schema.
    - opts: keywords of the schema.

  ## Examples

      iex> Xema.new :string, min_length: 3, max_length: 12
      %Xema{
        content: %Xema.Schema{
          max_length: 12,
          min_length: 3,
          type: :string
        }
      }

  For nested schemas you can use `{:type, opts: ...}` like here.

  ## Examples
      iex> schema = Xema.new :list, items: {:number, minimum: 2}
      %Xema{
        content: %Xema.Schema{
          type: :list,
          items: %Xema.Schema{
            type: :number,
            minimum: 2
          }
        }
      }
      iex> Xema.validate(schema, [2, 3, 4])
      :ok
      iex> Xema.valid?(schema, [2, 3, 4])
      true
      iex> Xema.validate(schema, [2, 3, 1])
      {:error, %{items: [{2, %{value: 1, minimum: 2}}]}}

  """
  @spec new(Schema.t() | Schema.type() | tuple, keyword) :: Xema.t()
  def new(type, keywords)

  defp init(type, keywords) when is_atom(type) do
    # IO.inspect({type, keywords})
    SchemaValidator.validate!({type, keywords})
    do_init(type, keywords)
  end

  defp init(keywords, []), do: init(:any, keywords)

  defp do_init({type}, []), do: do_init(type, [])

  defp do_init(list, []) when is_list(list) do
    case Keyword.keyword?(list) do
      true -> do_init(:any, list)
      false -> schema({list, []}, [])
    end
  end

  defp do_init(list, keywords) when is_list(list),
    do: schema({list, keywords}, [])

  defp do_init({type, keywords}, []),
    do: do_init(type, keywords)

  defp do_init(tuple, keywords) when is_tuple(tuple),
    do: raise(ArgumentError, message: "Invalid argument #{inspect(keywords)}.")

  defp do_init(bool, []) when is_boolean(bool),
    do: Schema.new(type: bool)

  defp do_init(map, []) when is_map(map), do: do_init(:any, Map.to_list(map))

  defp do_init(value, keywords) do
    case value in Schema.types() do
      true -> schema({value, keywords}, [])
      false -> do_init(:any, [{value, keywords}])
    end
  end

  #
  # function: schema
  #
  @spec schema(any, keyword) :: Schema.t()
  defp schema(type, keywords \\ [])

  defp schema(%{__struct__: _, content: schema}, _), do: schema

  defp schema(list, keywords) when is_list(list) do
    case Keyword.keyword?(list) do
      true ->
        schema({:any, list}, keywords)

      false ->
        schema({list, []}, keywords)
    end
  end

  defp schema(value, keywords)
       when not is_tuple(value),
       do: schema({value, []}, keywords)

  defp schema({list, keywords}, _) when is_list(list),
    do:
      keywords
      |> Keyword.put(:type, list)
      |> update()
      |> Schema.new()

  defp schema({bool, _}, _)
       when is_boolean(bool),
       do: Schema.new(type: bool)

  defp schema({value, keywords}, _) do
    case value in Schema.types() do
      true ->
        unless Keyword.keyword?(keywords) do
          raise(SchemaError,
            message:
              "Wrong argument for #{inspect(value)}. Argument: #{
                inspect(keywords)
              }"
          )
        end

        keywords
        |> Keyword.put(:type, value)
        |> update()
        |> Schema.new()

      false ->
        schema({:any, [{value, keywords}]})
    end
  end

  #
  # function: update/1
  #
  @spec update(keyword) :: keyword
  defp update(keywords) do
    keywords
    |> Keyword.update(:additional_items, nil, &bool_or_schema/1)
    |> Keyword.update(:additional_properties, nil, &bool_or_schema/1)
    |> Keyword.update(:all_of, nil, &schemas/1)
    |> Keyword.update(:any_of, nil, &schemas/1)
    |> Keyword.update(:contains, nil, &schema/1)
    |> Keyword.update(:dependencies, nil, &dependencies/1)
    |> Keyword.update(:else, nil, &schema/1)
    |> Keyword.update(:if, nil, &schema/1)
    |> Keyword.update(:items, nil, &items/1)
    |> Keyword.update(:not, nil, &schema/1)
    |> Keyword.update(:one_of, nil, &schemas/1)
    |> Keyword.update(:pattern_properties, nil, &properties/1)
    |> Keyword.update(:properties, nil, &properties/1)
    |> Keyword.update(:property_names, nil, &schema/1)
    |> Keyword.update(:definitions, nil, &properties/1)
    |> Keyword.update(:required, nil, &MapSet.new/1)
    |> Keyword.update(:then, nil, &schema/1)
    |> update_allow()
    |> update_data()
  end

  @spec schemas(list) :: list
  defp schemas(list), do: Enum.map(list, fn schema -> schema(schema) end)

  @spec properties(map) :: map
  defp properties(map),
    do: Enum.into(map, %{}, fn {key, prop} -> {key, schema(prop)} end)

  @spec dependencies(map) :: map
  defp dependencies(map),
    do:
      Enum.into(map, %{}, fn
        {key, dep} when is_list(dep) -> {key, dep}
        {key, dep} when is_boolean(dep) -> {key, schema(dep)}
        {key, dep} when is_atom(dep) -> {key, [dep]}
        {key, dep} when is_binary(dep) -> {key, [dep]}
        {key, dep} -> {key, schema(dep)}
      end)

  @spec bool_or_schema(boolean | atom) :: boolean | Schema.t()
  defp bool_or_schema(bool) when is_boolean(bool), do: bool

  defp bool_or_schema(schema), do: schema(schema)

  @spec items(any) :: list
  defp items(schema) when is_atom(schema) or is_tuple(schema),
    do: schema(schema)

  defp items(schemas) when is_list(schemas), do: schemas(schemas)

  defp items(items), do: items

  defp update_allow(keywords) do
    case Keyword.pop(keywords, :allow, :undefined) do
      {:undefined, keywords} ->
        keywords

      {value, keywords} ->
        Keyword.update!(keywords, :type, fn
          types when is_list(types) -> [value | types]
          type -> [type, value]
        end)
    end
  end

  defp update_data(keywords) do
    {data, keywords} = do_update_data(keywords)

    case data do
      data when map_size(data) == 0 ->
        Keyword.put(keywords, :data, nil)

      data ->
        Keyword.put(keywords, :data, data)
    end
  end

  defp do_update_data(keywords),
    do:
      keywords
      |> diff_keywords()
      |> Enum.reduce({%{}, keywords}, fn key, {data, keywords} ->
        {value, keywords} = Keyword.pop(keywords, key)
        {Map.put(data, key, maybe_schema(value)), keywords}
      end)

  defp maybe_schema(list) when is_list(list) do
    case Keyword.keyword?(list) do
      true ->
        case has_keyword?(list) do
          true -> schema(list)
          false -> list
        end

      false ->
        Enum.map(list, &maybe_schema/1)
    end
  end

  defp maybe_schema(atom) when is_atom(atom) do
    case atom in Schema.types() do
      true -> schema(atom)
      false -> atom
    end
  end

  defp maybe_schema({:ref, str} = ref) when is_binary(str),
    do: schema(ref)

  defp maybe_schema({atom, list} = tuple)
       when is_atom(atom) and is_list(list) do
    case atom in Schema.types() do
      true -> schema(tuple)
      false -> tuple
    end
  end

  defp maybe_schema(%{__struct__: _} = struct), do: struct

  defp maybe_schema(map) when is_map(map),
    do: Enum.into(map, %{}, fn {k, v} -> {k, maybe_schema(v)} end)

  defp maybe_schema(value), do: value

  defp diff_keywords(list),
    do:
      list
      |> Keyword.keys()
      |> MapSet.new()
      |> MapSet.difference(@keywords)
      |> MapSet.to_list()

  defp has_keyword?(list),
    do:
      list
      |> Keyword.keys()
      |> MapSet.new()
      |> MapSet.disjoint?(@keywords)
      |> Kernel.not()

  #
  # to_string
  #
  @spec to_string(Xema.t(), keyword) :: String.t()
  def to_string(%Xema{} = xema, opts \\ []) do
    opts
    |> Keyword.get(:format, :call)
    |> do_to_string(xema.content)
  end

  @spec do_to_string(atom, Schema.t()) :: String.t()
  defp do_to_string(:call, schema),
    do: "Xema.new(#{schema_to_string(schema, true)})"

  defp do_to_string(:data, schema), do: "{#{schema_to_string(schema, true)}}"

  @spec schema_to_string(Schema.t() | atom, atom) :: String.t()
  defp schema_to_string(schema, root \\ false)

  defp schema_to_string(%Schema{type: type} = schema, root),
    do:
      do_schema_to_string(
        type,
        schema |> Schema.to_map() |> Map.delete(:type),
        root
      )

  defp schema_to_string(schema, _root),
    do:
      schema
      |> Enum.sort()
      |> schema_to_string_data()
      |> Enum.map(&key_value_to_string/1)
      |> Enum.join(", ")

  defp schema_to_string_data(schema) do
    case Keyword.fetch(schema, :data) do
      {:ok, data} ->
        schema
        |> Keyword.delete(:data)
        |> Keyword.merge(Map.to_list(data))

      :error ->
        schema
    end
  end

  defp do_schema_to_string(type, schema, _root) when schema == %{},
    do: inspect(type)

  defp do_schema_to_string(:any, schema, true) do
    case Map.to_list(schema) do
      [{:ref, ref}] -> ~s(:ref, "#{ref.pointer}")
      [{key, value}] -> "#{inspect(key)}, #{value_to_string(value)}"
      _ -> ":any, #{schema_to_string(schema)}"
    end
  end

  defp do_schema_to_string(type, schema, true),
    do: "#{inspect(type)}, #{schema_to_string(schema)}"

  defp do_schema_to_string(type, schema, false),
    do: "{#{do_schema_to_string(type, schema, true)}}"

  @spec value_to_string(term) :: String.t()
  defp value_to_string(%Schema{} = schema), do: schema_to_string(schema)

  defp value_to_string(%{__struct__: Regex} = regex),
    do: ~s("#{Regex.source(regex)}")

  defp value_to_string(%{__struct__: MapSet} = map_set),
    do: value_to_string(map_set |> MapSet.new() |> MapSet.to_list())

  defp value_to_string(list) when is_list(list),
    do:
      list
      |> Enum.map(&value_to_string/1)
      |> Enum.join(", ")
      |> wrap("[", "]")

  defp value_to_string(map) when is_map(map),
    do:
      map
      |> Enum.map(&key_value_to_string/1)
      |> Enum.join(", ")
      |> wrap("%{", "}")

  defp value_to_string(:__nil__), do: "nil"

  defp value_to_string(value), do: inspect(value)

  @spec key_value_to_string({atom | String.t(), any}) :: String.t()
  defp key_value_to_string({:ref, %{__struct__: Xema.Ref} = ref}),
    do: ~s(ref: "#{ref.pointer}")

  defp key_value_to_string({key, value}) when is_atom(key),
    do: "#{key}: #{value_to_string(value)}"

  defp key_value_to_string({%{__struct__: Regex} = regex, value}),
    do: key_value_to_string({Regex.source(regex), value})

  defp key_value_to_string({key, value}),
    do: ~s("#{key}" => #{value_to_string(value)})

  @spec wrap(String.t(), String.t(), String.t()) :: String.t()
  defp wrap(str, trailing, pending), do: "#{trailing}#{str}#{pending}"
end

defimpl String.Chars, for: Xema do
  @spec to_string(Xema.t()) :: String.t()
  def to_string(xema), do: Xema.to_string(xema)
end

defimpl Inspect, for: Xema do
  def inspect(schema, opts) do
    map =
      schema
      |> Map.from_struct()
      |> Map.update!(:refs, fn map ->
        case map_size(map) == 0 do
          true -> nil
          false -> map
        end
      end)
      |> Enum.filter(fn {_, val} -> !is_nil(val) end)
      |> Enum.into(%{})

    Inspect.Map.inspect(map, "Xema", opts)
  end
end
