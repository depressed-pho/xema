defmodule Draft7.AdditionalPropertiesTest do
  use ExUnit.Case, async: true

  import Xema, only: [valid?: 2]

  describe "additionalProperties being false does not allow other properties" do
    setup do
      %{
        schema:
          Xema.new(
            additional_properties: false,
            pattern_properties: %{"^v" => :any},
            properties: %{bar: :any, foo: :any}
          )
      }
    end

    test "no additional properties is valid", %{schema: schema} do
      data = %{foo: 1}
      assert valid?(schema, data)
    end

    test "an additional property is invalid", %{schema: schema} do
      data = %{bar: 2, foo: 1, quux: "boom"}
      refute valid?(schema, data)
    end

    test "ignores arrays", %{schema: schema} do
      data = [1, 2, 3]
      assert valid?(schema, data)
    end

    test "ignores strings", %{schema: schema} do
      data = "foobarbaz"
      assert valid?(schema, data)
    end

    test "ignores other non-objects", %{schema: schema} do
      data = 12
      assert valid?(schema, data)
    end

    test "patternProperties are not additional properties", %{schema: schema} do
      data = %{foo: 1, vroom: 2}
      assert valid?(schema, data)
    end
  end

  describe "non-ASCII pattern with additionalProperties" do
    setup do
      %{
        schema:
          Xema.new(
            additional_properties: false,
            pattern_properties: %{"^á" => :any}
          )
      }
    end

    test "matching the pattern is valid", %{schema: schema} do
      data = %{ármányos: 2}
      assert valid?(schema, data)
    end

    test "not matching the pattern is invalid", %{schema: schema} do
      data = %{élmény: 2}
      refute valid?(schema, data)
    end
  end

  describe "additionalProperties allows a schema which should validate" do
    setup do
      %{
        schema:
          Xema.new(
            additional_properties: :boolean,
            properties: %{bar: :any, foo: :any}
          )
      }
    end

    test "no additional properties is valid", %{schema: schema} do
      data = %{foo: 1}
      assert valid?(schema, data)
    end

    test "an additional valid property is valid", %{schema: schema} do
      data = %{bar: 2, foo: 1, quux: true}
      assert valid?(schema, data)
    end

    test "an additional invalid property is invalid", %{schema: schema} do
      data = %{bar: 2, foo: 1, quux: 12}
      refute valid?(schema, data)
    end
  end

  describe "additionalProperties can exist by itself" do
    setup do
      %{schema: Xema.new(additional_properties: :boolean)}
    end

    test "an additional valid property is valid", %{schema: schema} do
      data = %{foo: true}
      assert valid?(schema, data)
    end

    test "an additional invalid property is invalid", %{schema: schema} do
      data = %{foo: 1}
      refute valid?(schema, data)
    end
  end

  describe "additionalProperties are allowed by default" do
    setup do
      %{schema: Xema.new(properties: %{bar: :any, foo: :any})}
    end

    test "additional properties are allowed", %{schema: schema} do
      data = %{bar: 2, foo: 1, quux: true}
      assert valid?(schema, data)
    end
  end

  describe "additionalProperties should not look in applicators" do
    setup do
      %{
        schema:
          Xema.new(
            additional_properties: :boolean,
            all_of: [[properties: %{foo: :any}]]
          )
      }
    end

    test "properties defined in allOf are not allowed", %{schema: schema} do
      data = %{bar: true, foo: 1}
      refute valid?(schema, data)
    end
  end
end
