defmodule SkoomaTest do
  use ExUnit.Case
  require Logger

  test "bool types" do
    test_data = false
    test_schema = [:bool]
    expected_results = :ok

    results = Skooma.valid?(test_data, test_schema)
    assert(expected_results == results)
  end

  test "string types" do
    test_data = "test"
    test_schema = [:string]
    expected_results = :ok

    results = Skooma.valid?(test_data, test_schema)
    assert(expected_results == results)
  end

  test "int types" do
    test_data = 7
    test_schema = :int
    expected_results = :ok

    results = Skooma.valid?(test_data, test_schema)
    assert(expected_results == results)
  end

  test "float types" do
    test_data = 3.14
    test_schema = [:float]
    expected_results = :ok

    results = Skooma.valid?(test_data, test_schema)
    assert(expected_results == results)
  end

  test "number types" do
    test_data = 3.14
    test_schema = [:number]
    expected_results = :ok

    results = Skooma.valid?(test_data, test_schema)
    assert(expected_results == results)
  end

  test "atom types" do
    test_data = :thing
    test_schema = [:atom]
    expected_results = :ok

    results = Skooma.valid?(test_data, test_schema)
    assert(expected_results == results)
  end

  test "union types with map" do
    test_data = %{key1: "value1"}
    test_schema = [:union, [%{key1: [:string]}, [:int]]]
    expected_results = :ok

    results = Skooma.valid?(test_data, test_schema)
    assert(expected_results == results)
  end

  test "union types" do
    test_data = 8
    test_schema = [:union, [[:map, %{key1: [:string]}], [:int]]]
    expected_results = :ok

    results = Skooma.valid?(test_data, test_schema)
    assert(expected_results == results)
  end

  test "keyword list types" do
    test_data = [key1: "value1", key2: 2, key3: :atom3]
    test_schema = [key1: [:string], key2: [:int], key3: [:atom]]
    expected_results = :ok

    results = Skooma.valid?(test_data, test_schema)
    assert(expected_results == results)
  end

  test "keyword list types complex" do
    test_data = [key1: %{key4: 6}, key2: 2, key3: :atom3]
    test_schema = [key1: [:map, %{key4: [:int]}], key2: [:int], key3: [:atom]]
    expected_results = :ok

    results = Skooma.valid?(test_data, test_schema)
    assert(expected_results == results)
  end

  test "map types simple" do
    test_data = %{:key1 => "value1", "key2" => 3}
    test_schema = %{:key1 => :string, "key2" => :int}
    expected_results = :ok

    results = Skooma.valid?(test_data, test_schema)
    assert(expected_results == results)
  end

  test "map types not_required" do
    test_data = %{"key2" => 3}
    test_schema = %{:key1 => [:string, :not_required], "key2" => [:int]}
    expected_results = :ok

    results = Skooma.valid?(test_data, test_schema)
    assert(expected_results == results)
  end

  test "map types not_required with nil" do
    test_data = %{:key1 => nil, "key2" => 3}
    test_schema = %{:key1 => [:string, :not_required], "key2" => [:int]}
    expected_results = :ok

    results = Skooma.valid?(test_data, test_schema)
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

    results = Skooma.valid?(test_data, test_schema)
    assert(expected_results == results)
  end

  test "map types complex not_required" do
    test_data = %{
      :key1 => "value1",
      "key2" => %{color: "blue"},
      "things" => ["thing1", "thing2"],
      "stuff" => %{key3: %{}}
    }
    test_schema = %{
      :key1 => [:string],
      "key2" => [:map, %{color: [:string]}],
      "things" => [:list, :string],
      "stuff" => %{key3: %{key4: [:string, :not_required]}}
    }
    expected_results = :ok

    results = Skooma.valid?(test_data, test_schema)
    assert(expected_results == results)
  end

  def hero_schema() do
    %{
      name: [:string],
      race: [:string],
      friends: [:list, :map, :not_required, &hero_schema/0]
    }
  end

  test "recursive map" do
    my_hero = %{
      name: "Alkosh",
      race: "Khajiit",
      friends: [ 
        %{name: "Asurah", race: "Khajiit"}, 
        %{name: "Carlos", race: "Dwarf"}
      ]
    }

    Skooma.valid?(my_hero, hero_schema()) # :ok
  end

  test "list types simple" do
    test_data = [1, 2, 3, 4]
    test_schema = [:list, :int]
    expected_results = :ok

    results = Skooma.valid?(test_data, test_schema)
    assert(expected_results == results)
  end

  test "list types empty" do
    test_data = []
    test_schema = [:list, :int]
    expected_results = :ok

    results = Skooma.valid?(test_data, test_schema)
    assert(expected_results == results)
  end

  test "list types complex" do
    test_data = [%{key1: "value1"}, %{key1: "value2"}, %{key1: "value 3"}]
    obj_schema = %{key1: [:string]}
    test_schema = [:list, :map, fn() -> obj_schema end]
    expected_results = :ok

    results = Skooma.valid?(test_data, test_schema)
    assert(expected_results == results)
  end

  test "tuple types simple" do
    test_data = {"thing1", 2, :atom3}
    test_schema = {[:string], [:int], [:atom]}
    expected_results = :ok

    results = Skooma.valid?(test_data, test_schema)
    assert(expected_results == results)
  end

  test "tuple types complex" do
    test_data = {"thing1", %{key1: "value1"}, :atom3}
    obj_schema = %{key1: [:string]}
    test_schema = {[:string], obj_schema, [:atom]}
    expected_results = :ok

    results = Skooma.valid?(test_data, test_schema)
    assert(expected_results == results)
  end
end
