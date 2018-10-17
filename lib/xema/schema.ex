defmodule Xema.Schema do
  @moduledoc """
  This module contains the struct for the keywords of a schema.

  Usually this struct will be just used by `xema`.

  ## Examples

      iex> schema = Xema.new :any
      %Xema{content: %Xema.Schema{type: :any}}
      iex> schema.content == %Xema.Schema{type: :any}
      true
  """

  alias Xema.Ref
  alias Xema.Schema
  alias Xema.SchemaError

  @typedoc """
  The struct contains the keywords for a schema.

  * `additional_items` disallow additional items, if set to false. The keyword
    can also contain a schema to specify the type of additional items.
  * `additional_properties` disallow additional properties, if set to true.
  * 'all_of' a list of schemas they must all be valid.
  * 'any_of' a list of schemas with any valid schema.
  * `comment` for the schema.
  * `const` specifies a constant.
  * `content_encoding` annotation for the encoding.
  * `content_media_type` annotation for the media type.
  * `contains` validates a list whether any item is valid for the given schema.
  * `data` none schema data.
  * `default` this keyword can be used to supply a default JSON value.
  * `definitions` contains schemas for reuse.
  * `dependencies` allows the schema of the map to change based on the presence
    of certain special properties
  * `description` of the schema.
  * `else` see `if`, `then`, `else`.
  * `enum` specifies an enumeration
  * `examples` the value of this keyword must be an array. There are no
    restrictions placed on the values within the array.
  * `exclusive_maximum` is a boolean. When true, it indicates that the range
    excludes the maximum value.
  * `exclusive_minimum` is a boolean. When true, it indicates that the range
    excludes the minimum value.
  * `format` semantic validation.
  * `id` a unique identifier.
  * `if`, `then`, `else`: These keywords work together to implement conditional
    application of a subschema based on the outcome of another subschema.
  * `items` specifies the type(s) of the items.
  * `keys` could be `:atoms` or `:strings`.
  * `max_items` the maximum length of list.
  * `max_length` the maximum length of string.
  * `max_properties` the maximum count of properties for the map.
  * `maximum` the maximum value.
  * `min_items` the minimal length of list.
  * `min_length` the minimal length of string.
  * `min_properties` the minimal count of properties for the map.
  * `minimum` the minimum value.
  * `module` the module of a struct.
  * `multiple_of` is a number greater 0. The value has to be a multiple of this
    number.
  * `not` negates the given schema
  * `one_of` the given data must be valid against exactly one of the given
    subschemas.
  * `pattern_properties` specifies schemas for properties by patterns
  * `pattern` restrict a string to a particular regular expression.
  * `properties` specifies schemas for properties.
  * `property_names` a schema to check property names.
  * `ref` a reference to a schema.
  * `required` contains a set of required properties.
  * `schema` declares the used schema.
  * `title` of the schema.
  * `then` see `if`, `then`, `else`
  * `type` specifies the data type for a schema.
  * `unique_items` disallow duplicate items, if set to true.
  """
  @type t :: %Schema{
          additional_items: Xema.t() | Schema.t() | boolean | nil,
          additional_properties: map | boolean | nil,
          all_of: [Schema.t()] | nil,
          any_of: [Schema.t()] | nil,
          comment: String.t() | nil,
          const: any,
          content_encoding: String.t() | nil,
          content_media_type: String.t() | nil,
          contains: Xema.t() | Schema.t(),
          data: any,
          default: any,
          definitions: map,
          dependencies: list | map | nil,
          description: String.t() | nil,
          else: Xema.t() | Schema.t() | nil,
          enum: list | nil,
          examples: [any],
          exclusive_maximum: boolean | number | nil,
          exclusive_minimum: boolean | number | nil,
          format: atom | nil,
          id: String.t() | nil,
          if: Xema.t() | Schema.t() | nil,
          items: list | Xema.t() | Schema.t() | nil,
          keys: atom | nil,
          max_items: pos_integer | nil,
          max_length: pos_integer | nil,
          max_properties: pos_integer | nil,
          maximum: number | nil,
          min_items: pos_integer | nil,
          min_length: pos_integer | nil,
          min_properties: pos_integer | nil,
          minimum: number | nil,
          module: atom | nil,
          multiple_of: number | nil,
          not: Schema.t() | nil,
          one_of: [Schema.t()] | nil,
          pattern: Regex.t() | nil,
          pattern_properties: map | nil,
          properties: map | nil,
          property_names: Xema.t() | Schema.t() | nil,
          ref: Ref.t() | nil,
          required: MapSet.t() | nil,
          schema: String.t() | nil,
          then: Xema.t() | Schema.t() | nil,
          title: String.t() | nil,
          type: type | [type],
          unique_items: boolean | nil
        }

  defstruct [
    :additional_items,
    :additional_properties,
    :all_of,
    :any_of,
    :comment,
    :const,
    :content_encoding,
    :content_media_type,
    :contains,
    :data,
    :default,
    :definitions,
    :dependencies,
    :description,
    :else,
    :enum,
    :examples,
    :exclusive_maximum,
    :exclusive_minimum,
    :format,
    :id,
    :if,
    :items,
    :keys,
    :max_items,
    :max_length,
    :max_properties,
    :maximum,
    :min_items,
    :min_length,
    :min_properties,
    :minimum,
    :module,
    :multiple_of,
    :not,
    :one_of,
    :pattern,
    :pattern_properties,
    :properties,
    :property_names,
    :ref,
    :required,
    :schema,
    :then,
    :title,
    :unique_items,
    type: :any
  ]

  @type type ::
          :any
          | :atom
          | :boolean
          | false
          | :float
          | :integer
          | :keyword
          | :list
          | :map
          | nil
          | :number
          | :string
          | :struct
          | true
          | :tuple

  @types [
    :any,
    :atom,
    :boolean,
    false,
    :float,
    :integer,
    :keyword,
    :list,
    :map,
    nil,
    :number,
    :string,
    :struct,
    true,
    :tuple
  ]

  @spec new(keyword) :: Schema.t()
  def new(opts) do
    struct!(Schema, opts |> validate_type!() |> update())
  rescue
    e in KeyError ->
      reraise(
        SchemaError,
        [message: "#{inspect(e.key)} is not a valid keyword."],
        __STACKTRACE__
      )
  end

  @spec to_map(Schema.t()) :: map
  def to_map(schema),
    do:
      schema
      |> Map.from_struct()
      |> delete_nils()

  @spec types :: [type]
  def types, do: @types

  @spec validate_type!(keyword) :: keyword
  defp validate_type!(opts) when is_list(opts) do
    with {:ok, type} <- fetch_type(opts),
         :ok <- validate_type(type) do
      opts
    else
      {:error, :not_exist} ->
        raise(SchemaError, message: "Missing type.")

      {:error, types} when is_list(types) ->
        raise(SchemaError, message: "Invalid types #{inspect(types)}.")

      {:error, type} ->
        raise(SchemaError, message: "Invalid type #{inspect(type)}.")
    end
  end

  # This function exist just to make the dialyzer happy.
  # See: https://github.com/elixir-lang/elixir/issues/7177
  @spec fetch_type(keyword) :: {:ok, any} | {:error, :not_exist}
  defp fetch_type(opts) do
    case Keyword.fetch(opts, :type) do
      :error -> {:error, :not_exist}
      result -> result
    end
  end

  @spec validate_type(atom) :: :ok | {:error, atom}
  defp validate_type(type) when type in @types, do: :ok

  @spec validate_type([atom]) :: :ok | {:error, [atom]}
  defp validate_type(types) when is_list(types) do
    types
    |> Enum.map(&validate_type/1)
    |> Enum.filter(fn
      :ok -> false
      _ -> true
    end)
    |> case do
      [] -> :ok
      errors -> {:error, Enum.map(errors, fn {:error, type} -> type end)}
    end
  end

  defp validate_type(type), do: {:error, type}

  @spec update(keyword) :: keyword
  defp update(opts),
    do:
      opts
      |> Keyword.update(:const, nil, &mark_nil/1)
      |> Keyword.update(:pattern, nil, &pattern/1)
      |> Keyword.update(:pattern_properties, nil, &pattern_properties/1)

  # |> Keyword.update(:ref, nil, &ref/1)

  @spec mark_nil(any) :: any | :__nil__
  defp mark_nil(nil), do: :__nil__

  defp mark_nil(value), do: value

  @spec pattern(Regex.t() | String.t() | atom) :: Regex.t()
  defp pattern(string) when is_binary(string), do: Regex.compile!(string)

  defp pattern(atom) when is_atom(atom), do: pattern(Atom.to_string(atom))

  defp pattern(regex), do: regex

  @spec pattern_properties(map) :: map
  defp pattern_properties(nil), do: nil

  defp pattern_properties(map) do
    for key_value <- map, into: %{}, do: pattern_property(key_value)
  end

  defp pattern_property({pattern, property}) when is_binary(pattern) do
    {Regex.compile!(pattern), property}
  end

  defp pattern_property({pattern, property}) when is_atom(pattern) do
    pattern_property({Atom.to_string(pattern), property})
  end

  defp pattern_property(key_value), do: key_value

  @spec delete_nils(map) :: map
  defp delete_nils(schema),
    do: for({k, v} <- schema, not is_nil(v), into: %{}, do: {k, v})
end

defimpl Inspect, for: Xema.Schema do
  def inspect(schema, opts) do
    map =
      schema
      |> Map.from_struct()
      |> Map.update!(
        :type,
        fn
          :any -> nil
          val -> val
        end
      )
      |> Enum.filter(fn {_, val} -> !is_nil(val) end)
      |> Enum.into(%{})

    Inspect.Map.inspect(map, "Xema.Schema", opts)
  end
end
