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

  test "string types" do
    test_data = "test"
    test_schema = [:string]
    expected_results = :ok

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


  def fav_schema do
    %{
      "color" => [:string],
      "number" => [:int]
    }
  end

  def obj_schema do
    %{
      "first_name" => [:string],
      :last_name => [:string],
      "middle_initial" => [:string, :not_required],
      :age => [:any, :not_required],
      :hobbies => [:list, :string],
      :favs => [:map, &fav_schema/0]
    }
  end

  def list_schema do
    [:list, :map, &obj_schema/0]
  end

  def fail_schema do
    [1, 2, 3]
  end

  test "validate good data" do
    test_data = %{
      "first_name" => "Bob",
      "middle_initial" => "a",
      :last_name => "Cooper",
      :hobbies => ["coding", "games"],
      :age => 7,
      :favs => %{"color" => "blue", "number" => 7}
    }
   # assert(Validator.valid?(test_data, obj_schema()) == :ok)
  end

  test "validate bad data" do
    test_data = [1, 2, 3]
    test_result = {:error, "Data is not a map"}
   # assert(Validator.valid?(test_data, obj_schema()) == test_result)
  end

end
