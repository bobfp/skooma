defmodule ValidatorTest do
  use ExUnit.Case
  require Logger

  test "bool types" do
    test_data = false
    test_schema = [:bool]
    expected_results = :ok

    results = Validator.valid?(test_data, test_schema)
    assert(expected_results == results)
  end

  test "bool type error" do
    test_data = "abcdef"
    test_schema = [:bool]
    expected_results = {:error, ["Expected BOOLEAN, got STRING \"abcdef\""]}

    results = Validator.valid?(test_data, test_schema)
    assert(expected_results == results)
  end

  test "string types" do
    test_data = "test"
    test_schema = [:string]
    expected_results = :ok

    results = Validator.valid?(test_data, test_schema)
    assert(expected_results == results)
  end

  test "string type errors" do
    test_data = 7
    test_schema = [:string]
    expected_results = {:error, ["Expected STRING, got INTEGER 7"]}

    results = Validator.valid?(test_data, test_schema)
    assert(expected_results == results)
  end

  test "int types" do
    test_data = 7
    test_schema = [:int]
    expected_results = :ok

    results = Validator.valid?(test_data, test_schema)
    assert(expected_results == results)
  end

  test "int types errors" do
    test_data = false
    test_schema = [:int]
    expected_results = {:error, ["Expected INTEGER, got BOOLEAN false"]}

    results = Validator.valid?(test_data, test_schema)
    assert(expected_results == results)
  end

  test "float types" do
    test_data = 3.14
    test_schema = [:float]
    expected_results = :ok

    results = Validator.valid?(test_data, test_schema)
    assert(expected_results == results)
  end

  test "number types" do
    test_data = 3.14
    test_schema = [:number]
    expected_results = :ok

    results = Validator.valid?(test_data, test_schema)
    assert(expected_results == results)
  end

  test "atom types" do
    test_data = :thing
    test_schema = [:atom]
    expected_results = :ok

    results = Validator.valid?(test_data, test_schema)
    assert(expected_results == results)
  end

  test "map types simple" do
    test_data = %{:key1 => "value1", "key2" => 3}
    test_schema = %{:key1 => [:string], "key2" => [:int]}
    expected_results = :ok

    results = Validator.valid?(test_data, test_schema)
    assert(expected_results == results)
  end

  test "map types complex" do
    test_data = %{
      :key1 => "value1",
      "key2" => %{color: "blue"},
      "things" => ["thing1", "thing2"],
      "stuff" => %{key3: %{key4: "thing4"}}
    }
    test_schema = %{
      :key1 => [:string],
      "key2" => [:map, %{color: [:string]}],
      "things" => [:list, :string],
      "stuff" => %{key3: %{key4: [:string]}}
    }
    expected_results = :ok

    results = Validator.valid?(test_data, test_schema)
    assert(expected_results == results)
  end

  test "list types simple" do
    test_data = [1, 2, 3, 4]
    test_schema = [:list, :int]
    expected_results = :ok

    results = Validator.valid?(test_data, test_schema)
    assert(expected_results == results)
  end

  test "list types complex" do
    test_data = [%{key1: "value1"}, %{key1: "value2"}, %{key1: "value 3"}]
    obj_schema = %{key1: [:string]}
    test_schema = [:list, :map, fn() -> obj_schema end]
    expected_results = :ok

    results = Validator.valid?(test_data, test_schema)
    assert(expected_results == results)
  end

  test "tuple types simple" do
    test_data = {"thing1", 2, :atom3}
    test_schema = {[:string], [:int], [:atom]}
    expected_results = :ok

    results = Validator.valid?(test_data, test_schema)
    assert(expected_results == results)
  end

  test "tuple types complex" do
    test_data = {"thing1", %{key1: "value1"}, :atom3}
    obj_schema = %{key1: [:string]}
    test_schema = {[:string], obj_schema, [:atom]}
    expected_results = :ok

    results = Validator.valid?(test_data, test_schema)
    assert(expected_results == results)
  end
end
