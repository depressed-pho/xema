defmodule Xema.ConstTest do
  use ExUnit.Case, async: true

  import Xema, only: [validate: 2]

  alias Xema.ValidationError

  describe "const: 42 - " do
    setup do
      %{schema: Xema.new(const: 42)}
    end

    test "type", %{schema: schema} do
      assert schema.schema.type == :any
    end

    test "validate/2 with a valid value", %{schema: schema} do
      assert validate(schema, 42) == :ok
    end

    test "validate/2 with an invalid value", %{schema: schema} do
      assert {:error,
              %ValidationError{
                reason: %{
                  const: 42,
                  value: 1
                }
              } = error} = validate(schema, 1)

      assert Exception.message(error) == "Expected 42, got 1."
    end
  end

  describe "const: nil - " do
    setup do
      %{schema: Xema.new(const: nil)}
    end

    test "validate/2 with a valid value", %{schema: schema} do
      assert validate(schema, nil) == :ok
    end

    test "validate/2 with an invalid value", %{schema: schema} do
      assert {:error,
              %ValidationError{
                reason: %{
                  const: nil,
                  value: 55
                }
              } = error} = validate(schema, 55)

      assert Exception.message(error) == "Expected nil, got 55."
    end
  end
end
