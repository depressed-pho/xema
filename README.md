# Xema
[![Build Status](https://travis-ci.org/hrzndhrn/xema.svg?branch=master)](https://travis-ci.org/hrzndhrn/xema)
[![Coverage Status](https://coveralls.io/repos/github/hrzndhrn/xema/badge.svg?branch=master)](https://coveralls.io/github/hrzndhrn/xema?branch=master)
[![Hex.pm](https://img.shields.io/hexpm/v/xema.svg)](https://hex.pm/packages/xema)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Xema is a schema validator inspired by [JSON Schema](http://json-schema.org).

Xema allows you to annotate and validate elixir data structures.

Xema is in early beta. If you try it and has an issue, report them.

## Installation

First, add Xema to your `mix.exs` dependencies:

```elixir
def deps do
  [{:xema, "~> 0.1"}]
end
```

Then, update your dependencies:

```Shell
$ mix deps.get
```

## Usage

Xema supported the following types to validate data structures.

* [Type any](#any)
* [Type nil](#nil)
* [Type boolean](#boolean)
* [Type string](#string)
  * [Length](#length)
  * [Regular Expression](#regex)
* [Types number, integer and float](#number)
  * [Multiples](#multi)
  * [Range](#range)
* [Type list](#list)
  * [Items](#items)
  * [Additional Items](#additional_items)
  * [Length](#list_length)
  * [Uniqueness](#unique)
* [Type map](#map)
  * [Keys](#keys)
  * [Properties](#properties)
  * [Required Properties](#required_properties)
  * [Additional Properties](#additional_properties)
  * [Pattern Properties](#pattern_properties)
  * [Size](#map_size)
* [Enumerations](#enum)

### <a name="any"></a> Type any

The schema any will accept any data.

```elixir
iex> import Xema
Xema
iex> schema = xema :any
%Xema{type: %Xema.Any{}}
iex> validate schema, 42
:ok
iex> validate schema, "foo"
:ok
iex> validate schema, nil
:ok
```

### <a name="nil"></a> Type nil

The nil type matches only `nil`.

```elixir
iex> import Xema
Xema
iex> schema = xema :nil
%Xema{type: %Xema.Nil{}}
iex> validate schema, nil
:ok
iex> validate schema, 0
{:error, %{type: :nil, value: 0}}
```

### <a name="boolean"></a> Type boolean

The boolean type matches only `true` and `false`.
```Elixir
iex> import Xema
Xema
iex> schema = xema :boolean
%Xema{type: %Xema.Boolean{}}
iex> validate schema, true
:ok
iex> is_valid? schema, false
true
iex> validate schema, 0
{:error, %{type: :boolean, value: 0}}
iex> is_valid? schema, nil
false
```

### <a name="string"></a> Type string

The string type is used for strings.

```elixir
iex> import Xema
Xema
iex> schema = xema :string
%Xema{type: %Xema.String{}}
iex> validate schema, "José"
:ok
iex> validate schema, 42
{:error, %{type: :string, value: 42}}
iex> is_valid? schema, "José"
true
iex> is_valid? schema, 42
false
```

#### <a name="length"></a> Length

The length of a string can be constrained using the `min_length` and `max_length`
keywords. For both keywords, the value must be a non-negative number.

```elixir
iex> import Xema
Xema
iex> schema = xema :string, min_length: 2, max_length: 3
%Xema{type: %Xema.String{min_length: 2, max_length: 3}}
iex> validate schema, "a"
{:error, %{value: "a", min_length: 2}}
iex> validate schema, "ab"
:ok
iex> validate schema, "abc"
:ok
iex> validate schema, "abcd"
{:error, %{value: "abcd", max_length: 3}}
```

#### <a name="regex"></a> Regular Expression

The `pattern` keyword is used to restrict a string to a particular regular
expression.

```Elixir
iex> import Xema
Xema
iex> schema = xema :string, pattern: ~r/[0-9]-[A-B]+/
%Xema{type: %Xema.String{pattern: ~r/[0-9]-[A-B]+/}}
iex> validate schema, "1-AB"
:ok
iex> validate schema, "foo"
{:error, %{value: "foo", pattern: ~r/[0-9]-[A-B]+/}}
```

### <a name="number"></a> Types number, integer and float
There are three numeric types in Xema: `number`, `integer` and `float`. They
share the same validation keywords.

The `number` type is used for numbers.
```Elixir
iex> import Xema
Xema
iex> schema = xema :number
%Xema{type: %Xema.Number{}}
iex> validate schema, 42
:ok
iex> validate schema, 21.5
:ok
iex> validate schema, "foo"
{:error, %{type: :number, value: "foo"}}
```

The `integer` type is used for integral numbers.
```Elixir
iex> import Xema
Xema
iex> schema = xema :integer
%Xema{type: %Xema.Integer{}}
iex> validate schema, 42
:ok
iex> validate schema, 21.5
{:error, %{type: :integer, value: 21.5}}
```

The `float` type is used for floating point numbers.
```Elixir
iex> import Xema
Xema
iex> schema = xema :float
%Xema{type: %Xema.Float{}}
iex> validate schema, 42
{:error, %{type: :float, value: 42}}
iex> validate schema, 21.5
:ok
```

#### <a name="multi"></a> Multiples
Numbers can be restricted to a multiple of a given number, using the
`multiple_of` keyword. It may be set to any positive number.

```Elixir
iex> import Xema
Xema
iex> schema = xema :number, multiple_of: 2
%Xema{type: %Xema.Number{multiple_of: 2}}
iex> validate schema, 8
:ok
iex> validate schema, 7
{:error, %{value: 7, multiple_of: 2}}
iex> is_valid? schema, 8.0
true
```

#### <a name="range"></a> Range
Ranges of numbers are specified using a combination of the `minimum`, `maximum`,
`exclusive_minimum` and `exclusive_maximum` keywords.
* `minimum` specifies a minimum numeric value.
* `exclusive_minimum` is a boolean. When true, it indicates that the range
   excludes the minimum value, i.e., x > minx > min. When false (or not included),
   it indicates that the range includes the minimum value, i.e., x≥minx≥min.
* `maximum` specifies a maximum numeric value.
* `exclusive_maximum` is a boolean. When true, it indicates that the range
   excludes the maximum value, i.e., x < maxx < max. When false (or not
   included), it indicates that the range includes the maximum value, i.e., x ≤
   maxx ≤ max.

```Elixir
iex> import Xema
Xema
iex> schema = xema :float, minimum: 1.2, maximum: 1.4, exclusive_maximum: true
%Xema{type: %Xema.Float{minimum: 1.2, maximum: 1.4, exclusive_maximum: true}}
iex> validate schema, 1.1
{:error, %{value: 1.1, minimum: 1.2}}
iex> validate schema, 1.2
:ok
iex> is_valid? schema, 1.3
true
iex> validate schema, 1.4
{:error, %{value: 1.4, maximum: 1.4, exclusive_maximum: true}}
iex> validate schema, 1.5
{:error, %{value: 1.5, maximum: 1.4, exclusive_maximum: true}}
```

### <a name="list"></a> Type list
List are used for ordered elements, each element may be of a different type.

```Elixir
iex> import Xema
Xema
iex> schema = xema :list
%Xema{type: %Xema.List{}}
iex> is_valid? schema, [1, "two", 3.0]
true
iex> validate schema, 9
{:error, %{type: :list, value: 9}}
```

#### <a name="items"></a> Items
The `items` keyword will be used to validate all items of a list to a single
schema.

```Elixir
iex> import Xema
Xema
iex> schema = xema :list, items: :string
%Xema{type: %Xema.List{items: %Xema.String{}}}
iex> is_valid? schema, ["a", "b", "abc"]
true
iex> validate schema, ["a", 1]
{:error, %{
  reason: :invalid_item,
  at: 1,
  error: %{type: :string, value: 1}}
}
```

The next example shows how to add keywords to the items schema.

```Elixir
iex> import Xema
Xema
iex> schema = xema :list, items: {:integer, minimum: 1, maximum: 10}
%Xema{type: %Xema.List{items: %Xema.Integer{minimum: 1, maximum: 10}}}
iex> validate schema, [1, 2, 3]
:ok
iex> validate schema, [3, 2, 1, 0]
{:error, %{
  reason: :invalid_item,
  at: 3,
  error: %{value: 0, minimum: 1}
}}
```

`items` can also be used to give each item a specific schema.

```Elixir
iex> import Xema
Xema
iex> schema = xema :list,
...>   items: [:integer, {:string, min_length: 5}]
%Xema{type: %Xema.List{
  items: [%Xema.Integer{}, %Xema.String{min_length: 5}]
}}
iex> is_valid? schema, [1, "hello"]
true
iex> validate schema, [1, "five"]
{
  :error,
  %{reason: :invalid_item, at: 1, error: %{value: "five", min_length: 5}}
}
# It’s okay to not provide all of the items:
iex> validate schema, [1]
:ok
# And, by default, it’s also okay to add additional items to end:
iex> validate schema, [1, "hello", "foo"]
:ok
```

#### <a name="additional_items"></a> Additional Items

The `additional_items` keyword controls whether it is valid to have additional
items in the array beyond what is defined in the schema.

```Elixir
iex> import Xema
Xema
iex> schema = xema :list,
...>   items: [:integer, {:string, min_length: 5}],
...>   additional_items: false
%Xema{type: %Xema.List{
  items: [%Xema.Integer{}, %Xema.String{min_length: 5}],
  additional_items: false
}}
# It’s okay to not provide all of the items:
iex> validate schema, [1]
:ok
# But, since additionalItems is false, we can’t provide extra items:
iex> validate schema, [1, "hello", "foo"]
{:error, %{reason: :additional_item, at: 2}}
iex> validate schema, [1, "hello", "foo", "bar"]
{:error, %{reason: :additional_item, at: 2}}
```

The keyword can also contain a schema to specify the type of additional items.
```Elixir
iex> import Xema
Xema
iex> schema = xema :list,
...>   items: [:integer, {:string, min_length: 3}],
...>   additional_items: :integer
%Xema{type: %Xema.List{
  items: [%Xema.Integer{}, %Xema.String{min_length: 3}],
  additional_items: %Xema.Integer{}
}}
iex> is_valid? schema, [1, "two", 3, 4]
true
iex> validate schema, [1, "two", 3, "four"]
{:error, %{
  reason: :invalid_item,
  at: 3,
  error: %{type: :integer, value: "four"}
}}
```

#### <a name="list_length"></a> Length

The length of the array can be specified using the `min_items` and `max_items`
keywords. The value of each keyword must be a non-negative number.

```Elixir
iex> import Xema
Xema
iex> schema = xema :list, min_items: 2, max_items: 3
%Xema{type: %Xema.List{min_items: 2, max_items: 3}}
iex> validate schema, [1]
{:error, %{value: [1], min_items: 2}}
iex> validate schema, [1, 2]
:ok
iex> validate schema, [1, 2, 3]
:ok
iex> validate schema, [1, 2, 3, 4]
{:error, %{value: [1, 2, 3, 4], max_items: 3}}
```

#### <a name="unique"></a> Uniqueness

A schema can ensure that each of the items in an array is unique.

```Elixir
iex> import Xema
Xema
iex> schema = xema :list, unique_items: true
%Xema{type: %Xema.List{unique_items: true}}
iex> is_valid? schema, [1, 2, 3]
true
iex> validate schema, [1, 2, 3, 2, 1]
{:error, %{value: [1, 2, 3, 2, 1], unique_items: true}}
```

### <a name="map"></a> Type map

Whenever you need a key-value store, maps are the “go to” data structure in
Elixir. Each of these pairs is conventionally referred to as a “property”.

```Elixir
iex> import Xema
Xema
iex> schema = xema :map
%Xema{type: %Xema.Map{}}
iex> is_valid? schema, %{"foo" => "bar"}
true
iex> validate schema, "bar"
{:error, %{type: :map, value: "bar"}}
# Using non-strings as keys are also valid:
iex> is_valid? schema, %{foo: "bar"}
true
iex> is_valid? schema, %{1 => "bar"}
true
```

#### <a name="keys"></a> Keys

The keyword `keys` can restrict the keys to atoms or strings.

Atoms as keys:
```Elixir
iex> import Xema
Xema
iex> schema = xema :map, keys: :atoms
%Xema{type: %Xema.Map{keys: :atoms}}
iex> is_valid? schema, %{"foo" => "bar"}
false
iex> is_valid? schema, %{foo: "bar"}
true
iex> is_valid? schema, %{1 => "bar"}
false
```

Strings as keys:
```Elixir
iex> import Xema
Xema
iex> schema = xema :map, keys: :strings
%Xema{type: %Xema.Map{keys: :strings}}
iex> is_valid? schema, %{"foo" => "bar"}
true
iex> is_valid? schema, %{foo: "bar"}
false
iex> is_valid? schema, %{1 => "bar"}
false
```

#### <a name="properties"></a> Properties

The properties on a map are defined using the `properties` keyword. The value
of properties is a map, where each key is the name of a property and each
value is a schema used to validate that property.

```Elixir
iex> import Xema
Xema
iex> schema = xema :map,
...>   properties: %{
...>     a: :integer,
...>     b: {:string, min_length: 5}
...>   }
%Xema{type: %Xema.Map{
  properties: %{
    a: %Xema.Integer{},
    b: %Xema.String{min_length: 5}
  }
}}
iex> is_valid? schema, %{a: 5, b: "hello"}
true
iex> validate schema, %{a: 5, b: "ups"}
{:error, %{
  reason: :invalid_property,
  property: :b,
  error: %{
    value: "ups",
    min_length: 5
  }
}}
# Additinonal properties are allowed by default:
iex> is_valid? schema, %{a: 5, b: "hello", add: :prop}
true
```

#### <a name="required_properties"></a> Required Properties

By default, the properties defined by the properties keyword are not required.
However, one can provide a list of `required` properties using the required
keyword.

```Elixir
iex> import Xema
Xema
iex> schema = xema :map, properties: %{foo: :string}, required: [:foo]
%Xema{
  type: %Xema.Map{
    properties: %{foo: %Xema.String{}},
    required: MapSet.new([:foo])
  }
}
iex> validate schema, %{foo: "bar"}
:ok
iex> validate schema, %{bar: "foo"}
{:error, %{reason: :missing_properties, missing: [:foo], required: [:foo]}}
```

#### <a name="additional_properties"></a> Additional Properties

The `additional_properties` keyword is used to control the handling of extra
stuff, that is, properties whose names are not listed in the properties keyword.
By default any additional properties are allowed.

The `additional_properties` keyword may be either a boolean or an schema. If
`additional_properties` is a boolean and set to false, no additional properties
will be allowed.

```Elixir
iex> import Xema
Xema
iex> schema = xema :map,
...>   properties: %{foo: :string},
...>   required: [:foo],
...>   additional_properties: false
%Xema{
  type: %Xema.Map{
    properties: %{foo: %Xema.String{}},
    required: MapSet.new([:foo]),
    additional_properties: false
  }
}
iex> validate schema, %{foo: "bar"}
:ok
iex> validate schema, %{foo: "bar", bar: "foo"}
{:error, %{
  reason: :no_additional_properties_allowed,
  additional_properties: [:bar]}
}
```

`additional_properties` can also contain a schema to specify the type of
additional properites.

```Elixir
iex> import Xema
Xema
iex> schema = xema :map,
...>   properties: %{foo: :string},
...>   additional_properties: :integer
%Xema{
  type: %Xema.Map{
    properties: %{foo: %Xema.String{}},
    additional_properties: %Xema.Integer{}
  }
}
iex> is_valid? schema, %{foo: "foo", add: 1}
true
iex> validate schema, %{foo: "foo", add: "one"}
{:error, %{
  reason: :invalid_property,
  property: :add,
  error: %{type: :integer, value: "one"}
}}
```

#### <a name="pattern_properties"></a> Pattern Properties

The keyword `pattern_properties` defined additional properties by regular
expressions.

```Eixir
iex> import Xema
Xema
iex> schema = xema :map,
...> additional_properties: false,
...> pattern_properties: %{
...>   ~r/^s_/ => :string,
...>   ~r/^i_/ => :integer
...> }
%Xema{type: %Xema.Map{
  additional_properties: false,
  pattern_properties: %{
    ~r/^s_/ => %Xema.String{},
    ~r/^i_/ => %Xema.Integer{}
  }
}}
iex> is_valid? schema, %{"s_0" => "foo", "i_1" => 6}
true
iex> is_valid? schema, %{s_0: "foo", i_1: 6}
true
iex> validate schema, %{s_0: "foo", f_1: 6.6}
{:error, %{
  reason: :no_additional_properties_allowed,
  additional_properties: [:f_1]
}}
```

#### <a name="map_size"></a> Size

The number of properties on an object can be restricted using the
`min_properties` and `max_properties` keywords.

```Elixir
iex> import Xema
Xema
iex> schema = xema :map,
...>   min_properties: 2,
...>   max_properties: 3
%Xema{type: %Xema.Map{
  min_properties: 2,
  max_properties: 3
}}
iex> is_valid? schema, %{a: 1, b: 2}
true
iex> validate schema, %{}
{:error, %{reason: :too_less_properties, min_properties: 2}}
iex> validate schema, %{a: 1, b: 2, c: 3, d: 4}
{:error, %{reason: :too_many_properties, max_properties: 3}}
```

#### <a name="dependencies"></a> Dependencies

The `dependencies` keyword allows the schema of the object to change based on
the presence of certain special properties.

```Elixir
iex> import Xema
Xema
iex> schema = xema :map,
...>   properties: %{
...>     a: :number,
...>     b: :number,
...>     c: :number
...>   },
...>   dependencies: %{
...>     b: [:c]
...>   }
%Xema{type: %Xema.Map{
  properties: %{a: %Xema.Number{}, b: %Xema.Number{}, c: %Xema.Number{}},
  dependencies: %{b: [:c]}
}}
iex> is_valid? schema, %{a: 5}
true
iex> is_valid? schema, %{c: 9}
true
iex> is_valid? schema, %{b: 1}
false
iex> is_valid? schema, %{b: 1, c: 7}
true
```

### <a name="enum"></a> Enumerations

The `enum` keyword is used to restrict a value to a fixed set of values. It must
be an array with at least one element, where each element is unique.

```Elixir
iex> import Xema
Xema
iex> schema = xema :any, enum: [1, "foo", :bar]
%Xema{type: %Xema.Any{enum: [1, "foo", :bar]}}
iex> is_valid? schema, :bar
true
iex> is_valid? schema, 42
false
```

## References

The home of JSON Schema: http://json-schema.org/

Specification:

* [JSON Schema core](http://json-schema.org/latest/json-schema-core.html)
defines the basic foundation of JSON Schema
* [JSON Schema Validation](http://json-schema.org/latest/json-schema-validation.html)
defines the validation keywords of JSON Schema


[Understanding JSON Schema](https://spacetelescope.github.io/understanding-json-schema/index.html)
a great tutorial for JSON Schema authors and a template for the description of
Xema.
