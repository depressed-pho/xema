defmodule Xema do
  @moduledoc """
  A schema validator inspired by [JSON Schema](http://json-schema.org)
  """

  use Xema.Behaviour

  alias Xema.Mapz
  alias Xema.Ref
  alias Xema.Schema
  alias Xema.SchemaValidator

  @keywords Schema.keywords()
  @types Schema.types()

  @doc """
  This function defines the schema.

  ## Examples

  Simple schema:

      iex> schema = Xema.new :string
      iex> Xema.valid? schema, "hello"
      true
      iex> Xema.valid? schema, 42
      false

  Schema:

      iex> schema = Xema.new {:string, min_length: 3, max_length: 12}
      iex> Xema.valid? schema, "hello"
      true
      iex> Xema.valid? schema, "hi"
      false

  Nested schemas:

      iex> schema = Xema.new {:list, items: {:number, minimum: 2}}
      iex> Xema.validate(schema, [2, 3, 4])
      :ok
      iex> Xema.valid?(schema, [2, 3, 4])
      true
      iex> Xema.validate(schema, [2, 3, 1])
      {:error, %{items: [{2, %{value: 1, minimum: 2}}]}}

  More examples can be found on page
  [Usage](https://hexdocs.pm/xema/usage.html#content).
  """
  @spec new(Schema.t() | Schema.type() | tuple | atom | keyword) :: Xema.t()
  def new(data)

  @impl true
  @doc false
  @spec init(atom | keyword | {atom | [atom], keyword}) :: Schema.t()
  def init(type) when is_atom(type), do: init({type, []})

  def init(val) when is_list(val) do
    case Keyword.keyword?(val) do
      true ->
        # init without a given type
        init({:any, val})

      false ->
        # init with multiple types
        init({val, []})
    end
  end

  def init({:ref, pointer}), do: init({:any, ref: pointer})

  def init(data) do
    SchemaValidator.validate!(data)
    schema(data)
  end

  #
  # function: schema
  #
  @spec schema(any, keyword) :: Schema.t()
  defp schema(type, keywords \\ [])

  defp schema({bool, _}, _) when is_boolean(bool), do: Schema.new(type: bool)

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

  defp schema({value, keywords}, _) do
    case value in Schema.types() do
      true ->
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
  defp update(keywords),
    do:
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

  @spec schemas(list) :: list
  defp schemas(list), do: Enum.map(list, fn schema -> schema(schema) end)

  @spec properties(map) :: map
  defp properties(map),
    do: Mapz.map_values(map, &schema/1)

  @spec dependencies(map) :: map
  defp dependencies(map),
    do:
      Enum.into(map, %{}, fn
        {key, dep} when is_list(dep) ->
          case Keyword.keyword?(dep) do
            true -> {key, schema(dep)}
            false -> {key, dep}
          end

        {key, dep} when is_boolean(dep) ->
          {key, schema(dep)}

        {key, dep} when is_atom(dep) ->
          {key, [dep]}

        {key, dep} when is_binary(dep) ->
          {key, [dep]}

        {key, dep} ->
          {key, schema(dep)}
      end)

  @spec bool_or_schema(boolean | atom) :: boolean | Schema.t()
  defp bool_or_schema(bool) when is_boolean(bool), do: bool

  defp bool_or_schema(schema), do: schema(schema)

  @spec items(any) :: list
  defp items(schema) when is_atom(schema) or is_tuple(schema),
    do: schema(schema)

  defp items(value) when is_list(value) do
    case Keyword.keyword?(value) do
      true ->
        case schemas?(value) do
          true -> schemas(value)
          false -> schema(value)
        end

      false ->
        schemas(value)
    end
  end

  defp items(items), do: items

  @spec schemas?(keyword) :: boolean
  defp schemas?(value),
    do:
      value
      |> Keyword.keys()
      |> Enum.all?(fn type -> type in [:ref | @types] end)

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

    cond do
      map_size(data) == 0 ->
        Keyword.put(keywords, :data, nil)

      true ->
        Keyword.put(keywords, :data, data)
    end
  end

  @spec do_update_data(keyword) :: {map, keyword}
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
    do: Mapz.map_values(map, &maybe_schema/1)

  defp maybe_schema(value), do: value

  defp diff_keywords(list),
    do:
      list
      |> Keyword.keys()
      |> MapSet.new()
      |> MapSet.difference(MapSet.new(@keywords))
      |> MapSet.to_list()

  defp has_keyword?(list),
    do:
      list
      |> Keyword.keys()
      |> MapSet.new()
      |> MapSet.disjoint?(MapSet.new(@keywords))
      |> Kernel.not()

  #
  #  source/1
  #

  @doc """
  Returns the source.

  ## Examples

      iex> {:integer, minimum: 1} |> Xema.new() |> Xema.source()
      {:integer, minimum: 1}
  """
  @spec source(Xema.t() | Schema.t()) :: atom | keyword | {atom, keyword}
  def source(%Xema{} = xema), do: source(xema.content)

  def source(%Schema{} = schema) do
    type = schema.type
    data = Map.get(schema, :data) || %{}

    keywords =
      schema
      |> Schema.to_map()
      |> Map.delete(:type)
      |> Map.delete(:data)
      |> Map.merge(data)
      |> Enum.map(fn {key, val} -> {key, nested_source(val)} end)
      |> map_ref()

    case {type, keywords} do
      {type, []} -> type
      {:any, keywords} -> keywords
      tuple -> tuple
    end
  end

  defp map_ref(keywords) do
    case Keyword.has_key?(keywords, :ref) do
      true ->
        if length(keywords) == 1 do
          keywords[:ref]
        else
          {_, pointer} = keywords[:ref]
          Keyword.put(keywords, :ref, pointer)
        end

      false ->
        keywords
    end
  end

  defp nested_source(%Schema{} = val), do: source(val)

  defp nested_source(%Ref{} = val), do: {:ref, val.pointer}

  defp nested_source(%MapSet{} = val), do: Map.keys(val.map)

  defp nested_source(%{__struct__: _} = val), do: val

  defp nested_source(val)
       when is_map(val),
       do: Mapz.map_values(val, &nested_source/1)

  defp nested_source(val)
       when is_list(val),
       do: Enum.map(val, &nested_source/1)

  defp nested_source(val), do: val
end
