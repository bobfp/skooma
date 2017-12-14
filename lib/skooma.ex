defmodule Skooma do
  require Logger
  alias Skooma.Utils

  def valid?(data, schema) do
    cond do
      is_tuple(schema) -> validate_tuple(data, schema)
      Keyword.keyword?(schema) -> validate_keyword(data, schema)
      is_map(schema) -> validate_map(data, schema)
      Enum.member?(schema, :list) -> validate_list(data, schema)
      Enum.member?(schema, :map) -> nested_map(data, schema)
      Enum.member?(schema, :union) -> union_handler(data, schema)
      Enum.member?(schema, :not_required) -> handle_not_required(data, schema)
      Enum.member?(schema, :string) -> is_binary(data) |> error(data, "STRING") |> custom_validator(data, schema)
      Enum.member?(schema, :int) -> is_integer(data) |> error(data, "INTEGER") |> custom_validator(data, schema)
      Enum.member?(schema, :float) -> is_float(data) |> error(data, "FLOAT") |> custom_validator(data, schema)
      Enum.member?(schema, :number) -> is_number(data) |> error(data, "NUMBER") |> custom_validator(data, schema)
      Enum.member?(schema, :bool) -> is_boolean(data) |> error(data, "BOOLEAN") |> custom_validator(data, schema)
      Enum.member?(schema, :atom) -> is_atom(data) |> error(data, "ATOM") |> custom_validator(data, schema)
      Enum.member?(schema, :any) -> :ok

      true -> {:error, ["Your data is all jacked up"]}
    end
  end

  defp union_handler(data, schema) do
    schemas = Enum.find(schema, &is_list/1)
    results = Enum.map(schemas, &(valid?(data, &1)))
    if Enum.any?(results, &(&1 == :ok)) do
      :ok
    else
      flattened_results = Enum.map(results, fn({:error, reason}) -> {:error, List.flatten(reason)}  end)
      {:error, Enum.map(flattened_results, fn({:error, [reason]}) -> "In Union, " <> reason end)}
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
        errors = Enum.map(validator_results, fn({:error, reason}) -> reason end)
        {:error, errors}
      end
    end
  end

  defp validate_keyword(data, schema) do
    if (Keyword.keys(data) |> length) == (Keyword.keys(schema) |> length) do
      results = Enum.map(data, fn({k,v}) -> valid?(v, schema[k]) end)
      |> Enum.reject(&(&1 == :ok))
      if Enum.count(results) == 0 do
        :ok
      else
        flattened_results = Enum.map(results, fn({:error, reason}) -> {:error, List.flatten(reason)}  end)
        {:error, Enum.map(flattened_results, fn({:error, [reason]}) -> "In keyword list, " <> reason end)}
      end
    else
      {:error, ["Missing some keys"]}
    end
  end

  defp nested_map(data, parent_schema) do
    schema = Enum.find(parent_schema, &is_function/1)
    clean_schema = if schema,  do: schema.(), else: Enum.find(parent_schema, &is_map/1)
    valid?(data, clean_schema)
  end

   defp error(bool, data, expected_type) do
    data_type = Utils.typeof(data)
    if bool do
      :ok
    else
      {:error, ["Expected #{expected_type}, got #{data_type} #{inspect data}"]}
    end
  end

  defp validate_list(data, schema) do
    list_schema = Enum.reject(schema, &(&1 == :list))
    results = Enum.map(data, &(valid?(&1, list_schema)))
    |> Enum.reject(&(&1 == :ok))
    if Enum.count(results) == 0 do
      :ok
    else
      flattened_results = Enum.map(results, fn({:error, reason}) -> {:error, List.flatten(reason)}  end)
      {:error, Enum.map(flattened_results, fn({:error, [reason]}) -> "In list, " <> reason end)}
    end
  end

  defp validate_tuple(data, schema) do
    data_list = Tuple.to_list(data)
    schema_list = Tuple.to_list(schema)
    if Enum.count(data_list) == Enum.count(schema_list) do
      result = Enum.zip(data_list, schema_list)
      |> Enum.map(&(valid?(elem(&1, 0), elem(&1, 1))))
      |> Enum.reject(&(&1 == :ok))

      if Enum.count(result) == 0 do
        :ok
      else
        flattened_results = Enum.map(result, fn({:error, reason}) -> {:error, List.flatten(reason)}  end)
        {:error, Enum.map(flattened_results, fn({:error, [reason]}) -> "In tuple, " <> reason end)}
      end
    else
      {:error, ["Tuple schema doesn't match tuple length"]}
    end
  end

  defp validate_map(data, schema) do
    data
    |> map_handler
    |> key_handler(schema)
    |> value_handler(schema)
    |> result_handler
  end

  defp result_handler(results) do
    case results do
      :ok -> :ok
      [error: [error]] -> {:error, [error] |> List.flatten}
      {:error, error} -> {:error, [error] |> List.flatten}
      [error: error] -> {:error, [error]}
        _ -> {:error, Keyword.values(results) |> List.flatten}
    end

  end

  defp map_handler(data) do
    if is_map(data) do
      data
    else
      {:error, ["Data is not a map"]}
    end
  end

  defp key_handler(data, schema) do
    case data do
      {:error, reason} -> {:error, reason}
      _ -> schema
          |> Enum.map(&get_required_keys/1)
          |> Enum.reject(&is_nil/1)
          |> validate_keys(data)
    end
  end

  defp get_required_keys({k, v}) do
    if (Enum.member?(v, :not_required)), do: nil, else: k
  end

  defp validate_keys(required_keys, data) do
    missing_keys = required_keys -- Map.keys(data)
    if Enum.count(missing_keys) == 0 do
      data
    else
      {data, {:error, "Missing required keys: #{inspect missing_keys}"}}
    end
  end

  defp validate_child({k, v}, schema) do
    if schema[k] |> is_nil do
      :ok
    else
      valid?(v, schema[k])
    end
  end

  defp value_handler(data, schema) do
    case data do
      {data, {:error, reason}} ->
        results = Enum.map(data, &(validate_child(&1, schema)))
        |> Enum.filter(&(&1 != :ok))
        [error: reason] ++ results
      {:error, reason} -> {:error, reason}
      _ ->
        results = Enum.map(data, &(validate_child(&1, schema)))
        |> Enum.filter(&(&1 != :ok))

        if Enum.count(results) == 0 do
          :ok
        else
          results
        end
    end
  end
end
