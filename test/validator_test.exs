defmodule ValidatorTest do
  use ExUnit.Case
  require Logger

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
    assert(Validator.valid?(test_data, obj_schema()) == :ok)
  end

  test "validate bad data" do
    test_data = [1, 2, 3]
    test_result = {:error, "Data is not a map"}
    assert(Validator.valid?(test_data, obj_schema()) == test_result)
  end

end
