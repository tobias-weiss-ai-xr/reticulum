defmodule Ret.ChemistryTest do
  use ExUnit.Case, async: true

  alias Ret.Chemistry

  describe "all_elements/0" do
    test "returns 118 elements" do
      assert length(Chemistry.all_elements()) == 118
    end

    test "elements have required keys" do
      required_keys = [:symbol, :name, :atomic_number, :mass, :group, :period, :block, :group_number, :color, :description, :theme, :experiments]

      Chemistry.all_elements()
      |> Enum.each(fn element ->
        Enum.each(required_keys, fn key ->
          assert Map.has_key?(element, key),
            "Element #{element[:symbol]} missing key #{key}"
        end)
      end)
    end

    test "all symbols are unique" do
      symbols = Chemistry.all_elements() |> Enum.map(& &1.symbol)
      assert length(symbols) == length(Enum.uniq(symbols))
    end
  end

  describe "element_for_symbol/1" do
    test "returns element for valid symbol" do
      assert %{symbol: "H", name: "Wasserstoff"} = Chemistry.element_for_symbol("H")
      assert %{symbol: "He", name: "Helium"} = Chemistry.element_for_symbol("He")
      assert %{symbol: "Fe", name: "Eisen"} = Chemistry.element_for_symbol("Fe")
      assert %{symbol: "U", name: "Uran"} = Chemistry.element_for_symbol("U")
      assert %{symbol: "Og", name: "Oganesson"} = Chemistry.element_for_symbol("Og")
    end

    test "returns nil for unknown symbol" do
      assert is_nil(Chemistry.element_for_symbol("Zz"))
      assert is_nil(Chemistry.element_for_symbol(""))
    end

    test "returns nil for non-string input" do
      assert is_nil(Chemistry.element_for_symbol(nil))
      assert is_nil(Chemistry.element_for_symbol(123))
    end
  end

  describe "valid_element_symbol?/1" do
    test "returns true for known symbols" do
      assert Chemistry.valid_element_symbol?("H")
      assert Chemistry.valid_element_symbol?("He")
      assert Chemistry.valid_element_symbol?("Fe")
    end

    test "returns false for unknown symbols" do
      refute Chemistry.valid_element_symbol?("Zz")
      refute Chemistry.valid_element_symbol?("")
    end

    test "returns false for non-string input" do
      refute Chemistry.valid_element_symbol?(nil)
      refute Chemistry.valid_element_symbol?(123)
    end
  end

  describe "validate_chemistry_data/1" do
    test "accepts valid chemistry data" do
      assert :ok = Chemistry.validate_chemistry_data(%{"symbol" => "H"})
      assert :ok = Chemistry.validate_chemistry_data(%{"symbol" => "Fe", "theme" => "forge", "experiments" => ["magnet", "rust"]})
    end

    test "accepts nil" do
      assert :ok = Chemistry.validate_chemistry_data(nil)
    end

    test "rejects invalid symbol" do
      assert {:error, "Invalid element symbol: Zz"} = Chemistry.validate_chemistry_data(%{"symbol" => "Zz"})
    end

    test "rejects data without symbol field" do
      assert {:error, "Chemistry data must contain a 'symbol' field"} = Chemistry.validate_chemistry_data(%{"theme" => "forge"})
      assert {:error, "Chemistry data must contain a 'symbol' field"} = Chemistry.validate_chemistry_data(%{})
    end

    test "accepts atom keys" do
      assert :ok = Chemistry.validate_chemistry_data(%{symbol: "H"})
    end
  end

  describe "valid_groups/0" do
    test "returns all 10 element groups" do
      expected = [:nonmetal, :nobleGas, :alkali, :alkalineEarth, :metalloid, :halogen, :transition, :metal, :lanthanide, :actinide]
      assert Chemistry.valid_groups() == expected
    end
  end
end
