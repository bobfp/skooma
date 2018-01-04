defmodule Skooma do
  require Logger
  alias Skooma.Utils

  def valid?(data, schema) do
    results = cond do
      is_atom(schema) -> valid?(data, [schema])
      is_tuple(schema) -> validate_tuple(data, schema)
      Keyword.keyword?(schema) -> validate_keyword(data, schema)
      is_map(schema) -> Skooma.Map.validate_map(data, schema)
      Enum.member?(schema, :list) -> validate_list(data, schema)
      Enum.member?(schema, :map) -> Skooma.Map.nested_map(data, schema)
      Enum.member?(schema, :union) -> union_handler(data, schema)
      Enum.member?(schema, :not_required) -> handle_not_required(data, schema)
      Enum.member?(schema, :string) -> basic_validator(&is_binary/1, "STRING", data, schema)
      Enum.member?(schema, :int) -> basic_validator(&is_integer/1, "INTEGER", data, schema)
      Enum.member?(schema, :float) -> basic_validator(&is_float/1, "FLOAT", data, schema)
      Enum.member?(schema, :number) -> basic_validator(&is_number/1, "NUMBER", data, schema)
      Enum.member?(schema, :bool) -> basic_validator(&is_boolean/1, "BOOLEAN", data, schema)
      Enum.member?(schema, :atom) -> basic_validator(&is_atom/1, "ATOM", data, schema)
      Enum.member?(schema, :any) -> :ok

      true -> {:error, "Your data is all jacked up"}
    end
    handle_results(results)
  end

  defp basic_validator(validator, type, data, schema) do
    data
    |> validator.()
    |> error(data, type)
    |> custom_validator(data, schema)
  end

  defp handle_results(:ok), do: :ok
  defp handle_results({:error, error}), do: {:error, [error]}
  defp handle_results(results) do
    case results |> Enum.reject(&(&1 == :ok)) do
      [] -> :ok
      errors ->
        errors
        |> List.flatten
        |> Enum.map(fn({:error, error}) -> {:error, List.flatten([error])} end)
        |> Enum.map(fn({:error, [error]}) -> error end)
        |> (fn(n) -> {:error, n} end).()
    end
  end

  defp union_handler(data, schema) do
    schemas = Enum.find(schema, &is_list/1)
    results = Enum.map(schemas, &(valid?(data, &1)))
    if Enum.any?(results, &(&1 == :ok)) do
      :ok
    else
      results
    end
  end

  defp handle_not_required(data, schema) do
    if data == nil do
      :ok
    else
      valid?(data, Enum.reject(schema, &(&1 == :not_required)))
    end
  end

  defp custom_validator(result, data, schema) do
    case result do
      :ok -> do_custom_validator(data, schema)
      _ -> result
    end
  end

  defp do_custom_validator(data, schema) do
    validators = Enum.filter(schema, &is_function/1)
    if Enum.count(validators) == 0 do
      :ok
    else
      validator_results = Enum.map(validators, &(&1.(data)))
      |> Enum.reject(&(&1 == :ok || &1 == true))
      |> Enum.map(&(if (&1 == false), do: {:error, "Value does not match custom validator"}, else: &1))
      if Enum.count(validator_results) == 0 do
        :ok
      else
        validator_results
      end
    end
  end

  defp validate_keyword(data, schema) do
    if (Keyword.keys(data) |> length) == (Keyword.keys(schema) |> length) do
      Enum.map(data, fn({k,v}) -> valid?(v, schema[k]) end)
      |> Enum.reject(&(&1 == :ok))
    else
      {:error, "Missing some keys"}
    end
  end

   defp error(bool, data, expected_type) do
    data_type = Utils.typeof(data)
    if bool do
      :ok
    else
      {:error, "Expected #{expected_type}, got #{data_type} #{inspect data}"}
    end
  end

  defp validate_list(data, schema) do
    list_schema = Enum.reject(schema, &(&1 == :list))
    Enum.map(data, &(valid?(&1, list_schema)))
  end

  defp validate_tuple(data, schema) do
    data_list = Tuple.to_list(data)
    schema_list = Tuple.to_list(schema)
    if Enum.count(data_list) == Enum.count(schema_list) do
      Enum.zip(data_list, schema_list)
      |> Enum.map(&(valid?(elem(&1, 0), elem(&1, 1))))
      |> Enum.reject(&(&1 == :ok))
    else
      {:error, "Tuple schema doesn't match tuple length"}
    end
  end

end
