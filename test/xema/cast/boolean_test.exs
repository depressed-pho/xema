defmodule Xema.Cast.BooleanTest do
  use ExUnit.Case, async: true

  alias Xema.CastError

  import Xema, only: [cast: 2, cast!: 2, validate: 2]

  @set [:foo, 1, 1.0, [42], [foo: 42], %{}, {:tuple}]

  describe "cast/2 with a minimal boolean schema" do
    setup do
      %{
        schema: Xema.new(:boolean)
      }
    end

    test "from a boolean", %{schema: schema} do
      assert cast(schema, true) == {:ok, true}
      assert cast(schema, false) == {:ok, false}
    end

    test "from a string", %{schema: schema} do
      assert validate(schema, "true") == {:error, %{type: :boolean, value: "true"}}
      assert validate(schema, "false") == {:error, %{type: :boolean, value: "false"}}
    end

    test "from an invalid type", %{schema: schema} do
      Enum.each(@set, fn data ->
        assert cast(schema, data) ==
                 {:error, %{path: [], to: :boolean, value: data}}
      end)
    end

    test "from a type without protocol implementation", %{schema: schema} do
      assert_raise(Protocol.UndefinedError, fn ->
        cast(schema, ~r/.*/)
      end)
    end
  end

  describe "cast!/2 with a minimal integer schema" do
    setup do
      %{
        schema: Xema.new(:boolean)
      }
    end

    test "from a boolean", %{schema: schema} do
      assert cast!(schema, true) == true
      assert cast!(schema, false) == false
    end

    test "from a string", %{schema: schema} do
      assert_raise_cast_error(schema, "true")
      assert_raise_cast_error(schema, "false")
    end

    test "from a type without protocol implementation", %{schema: schema} do
      assert_raise(Protocol.UndefinedError, fn ->
        cast!(schema, ~r/.*/)
      end)
    end

    test "from an invalid type", %{schema: schema} do
      Enum.each(@set, fn data -> assert_raise_cast_error(schema, data) end)
    end

    defp assert_raise_cast_error(schema, data) do
      msg = "cannot cast #{inspect(data)} to :boolean"

      assert_raise CastError, msg, fn ->
        cast!(schema, data)
      end
    end
  end
end
