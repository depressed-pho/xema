defmodule Xema.ListTest do
  use ExUnit.Case, async: true

  doctest Xema.List

  import Xema

  describe "'list' schema" do
    setup do
      %{schema: xema(:list)}
    end

    test "type", %{schema: schema} do
      assert schema.type.as == :list
    end

    test "validate/2 with an empty list", %{schema: schema} do
      assert validate(schema, []) == :ok
    end

    test "validate/2 with an list of different types", %{schema: schema} do
      assert validate(schema, [1, "bla", 3.4]) == :ok
    end

    test "validate/2 with an invalid value", %{schema: schema} do
      expected = {:error, %{type: :list, value: "not an array"}}

      assert validate(schema, "not an array") == expected
    end

    test "is_valid?/2 with a valid value", %{schema: schema} do
      assert is_valid?(schema, [1])
    end

    test "is_valid?/2 with an invalid value", %{schema: schema} do
      refute is_valid?(schema, 42)
    end
  end

  describe "'list' schema with size" do
    setup do
      %{schema: xema(:list, min_items: 2, max_items: 3)}
    end

    test "validate/2 with too short list", %{schema: schema} do
      assert validate(schema, [1]) == {:error, %{value: [1], min_items: 2}}
    end

    test "validate/2 with proper list", %{schema: schema} do
      assert validate(schema, [1, 2]) == :ok
    end

    test "validate/2 with to long list", %{schema: schema} do
      assert validate(schema, [1, 2, 3, 4]) ==
               {:error, %{value: [1, 2, 3, 4], max_items: 3}}
    end
  end

  describe "'list' schema with typed items" do
    setup do
      %{
        integers: xema(:list, items: :integer),
        strings: xema(:list, items: :string)
      }
    end

    test "validate/2 integers with empty list", %{integers: schema} do
      assert validate(schema, []) == :ok
    end

    test "validate/2 integers with list of integers", %{integers: schema} do
      assert validate(schema, [1, 2]) == :ok
    end

    test "validate/2 integers with invalid list", %{integers: schema} do
      expected =
        {
          :error,
          %{
            reason: :invalid_item,
            at: 2,
            error: %{type: :integer, value: "foo"}
          }
        }

      assert validate(schema, [1, 2, "foo"]) == expected
    end

    test "validate/2 strings with empty list", %{strings: schema} do
      assert validate(schema, []) == :ok
    end

    test "validate/2 strings with list of string", %{strings: schema} do
      assert validate(schema, ["foo"]) == :ok
    end

    test "validate/2 strings with invalid list", %{strings: schema} do
      expected =
        {
          :error,
          %{
            reason: :invalid_item,
            at: 0,
            error: %{type: :string, value: 1}
          }
        }

      assert validate(schema, [1, 2, "foo"]) == expected
    end
  end

  describe "'list' schema with unique items" do
    setup do
      %{schema: xema(:list, unique_items: true)}
    end

    test "validate/2 with list of unique items", %{schema: schema} do
      assert validate(schema, [1, 2, 3]) == :ok
    end

    test "validate/2 with list of not unique items", %{schema: schema} do
      assert validate(schema, [1, 2, 3, 3, 4]) ==
               {:error, %{value: [1, 2, 3, 3, 4], unique_items: true}}
    end
  end

  describe "'list' schema with tuple validation" do
    setup do
      %{
        schema:
          xema(
            :list,
            items: [
              {:string, min_length: 3},
              {:number, minimum: 10}
            ]
          )
      }
    end

    test "validate/2 with valid values", %{schema: schema} do
      assert validate(schema, ["foo", 42]) == :ok
    end

    test "validate/2 with invalid values", %{schema: schema} do
      assert validate(schema, ["foo", "bar"]) ==
               {:error, %{
                 reason: :invalid_item,
                 at: 1,
                 error: %{type: :number, value: "bar"}
               }}

      assert validate(schema, ["x", 33]) ==
               {:error, %{
                 reason: :invalid_item,
                 at: 0,
                 error: %{value: "x", min_length: 3}
               }}
    end

    test "validate/2 with additional item", %{schema: schema} do
      assert validate(schema, ["foo", 42, "add"]) == :ok
    end

    test "validate/2 with missing item", %{schema: schema} do
      assert validate(schema, ["foo"]) == :ok
    end
  end

  describe "'list' schema with tuple validation without addtional items" do
    setup do
      %{
        schema:
          xema(
            :list,
            additional_items: false,
            items: [
              {:string, min_length: 3},
              {:number, minimum: 10}
            ]
          )
      }
    end

    test "validate/2 with additional item", %{schema: schema} do
      expected = {:error, %{at: 2, reason: :additional_item}}
      assert validate(schema, ["foo", 42, "add"]) == expected
    end
  end

  describe "list schema with with specific additional items" do
    setup do
      %{
        schema:
          xema(
            :list,
            additional_items: :string,
            items: [
              {:number, minimum: 10}
            ]
          )
      }
    end

    test "validate/2 with valid additional item", %{schema: schema} do
      assert validate(schema, [11, "twelve", "thirteen"]) == :ok
    end

    test "validate/2 with invalid additional item", %{schema: schema} do
      assert validate(schema, [11, "twelve", 13]) ==
               {:error, %{
                 reason: :invalid_item,
                 at: 2,
                 error: %{type: :string, value: 13}
               }}
    end
  end
end
