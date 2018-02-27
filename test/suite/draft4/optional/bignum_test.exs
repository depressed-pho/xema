defmodule Suite.Draft4.Optional.BignumTest do
  use ExUnit.Case, async: true

  import Xema, only: [is_valid?: 2]

  describe "integer" do
    setup do
      %{schema: Xema.new(:integer)}
    end

    @tag :draft4
    @tag :bignum
    test "a bignum is an integer", %{schema: schema} do
      data =
        12_345_678_910_111_213_141_516_171_819_202_122_232_425_262_728_293_031

      assert is_valid?(schema, data)
    end

    @tag :draft4
    @tag :bignum
    test "a negative bignum is an integer", %{schema: schema} do
      data =
        -12_345_678_910_111_213_141_516_171_819_202_122_232_425_262_728_293_031

      assert is_valid?(schema, data)
    end
  end

  describe "number" do
    setup do
      %{schema: Xema.new(:number)}
    end

    @tag :draft4
    @tag :bignum
    test "a bignum is a number", %{schema: schema} do
      data =
        98_249_283_749_234_923_498_293_171_823_948_729_348_710_298_301_928_331

      assert is_valid?(schema, data)
    end

    @tag :draft4
    @tag :bignum
    test "a negative bignum is a number", %{schema: schema} do
      data =
        -98_249_283_749_234_923_498_293_171_823_948_729_348_710_298_301_928_331

      assert is_valid?(schema, data)
    end
  end

  describe "string" do
    setup do
      %{schema: Xema.new(:string)}
    end

    @tag :draft4
    @tag :bignum
    test "a bignum is not a string", %{schema: schema} do
      data =
        98_249_283_749_234_923_498_293_171_823_948_729_348_710_298_301_928_331

      refute is_valid?(schema, data)
    end
  end

  describe "integer comparison with maximum" do
    setup do
      %{schema: Xema.new(:maximum, 18_446_744_073_709_551_615)}
    end

    @tag :draft4
    @tag :bignum
    test "comparison works for high numbers", %{schema: schema} do
      data = 18_446_744_073_709_551_600
      assert is_valid?(schema, data)
    end
  end

  describe "float comparison with high precision" do
    setup do
      %{
        schema:
          Xema.new(:any, exclusive_maximum: true, maximum: 9.727837981879871e26)
      }
    end

    @tag :draft4
    @tag :bignum
    test "comparison works for high numbers", %{schema: schema} do
      data = 9.727837981879871e26
      refute is_valid?(schema, data)
    end
  end

  describe "integer comparison with minimum" do
    setup do
      %{schema: Xema.new(:minimum, -18_446_744_073_709_551_615)}
    end

    @tag :draft4
    @tag :bignum
    test "comparison works for very negative numbers", %{schema: schema} do
      data = -18_446_744_073_709_551_600
      assert is_valid?(schema, data)
    end
  end

  describe "float comparison with high precision on negative numbers" do
    setup do
      %{
        schema:
          Xema.new(
            :any,
            exclusive_minimum: true,
            minimum: -9.727837981879871e26
          )
      }
    end

    @tag :draft4
    @tag :bignum
    test "comparison works for very negative numbers", %{schema: schema} do
      data = -9.727837981879871e26
      refute is_valid?(schema, data)
    end
  end
end
