defmodule Validator do
  require Logger
  def valid?(data, schema) do
    cond do
      is_tuple(schema) -> validate_tuple(data, schema)
      is_map(schema) -> validate_map(data, schema)
      Enum.member?(schema, :list) -> validate_list(data, schema)
      Enum.member?(schema, :map) -> nested_map(data, schema)
      Enum.member?(schema, :string) -> is_binary(data) |> error(data, "STRING")
      Enum.member?(schema, :int) -> is_integer(data) |> error(data, "INTEGER")
      Enum.member?(schema, :float) -> is_float(data) |> error(data, "FLOAT")
      Enum.member?(schema, :number) -> is_number(data) |> error(data, "NUMBER")
      Enum.member?(schema, :bool) -> is_boolean(data) |> error(data, "BOOLEAN")
      Enum.member?(schema, :atom) -> is_atom(data) |> error(data, "ATOM")
      Enum.member?(schema, :any) -> :ok

      true -> {:error, "Your data is all jacked up"}
    end
  end

  defp nested_map(data, parent_schema) do
    schema = Enum.find(parent_schema, &is_function/1)
    clean_schema = if schema,  do: schema.(), else: Enum.find(parent_schema, &is_map/1)
    valid?(data, clean_schema)
  end

  def typeof(self) do
    cond do
      is_float(self)    -> "FLOAT"
      is_integer(self)  -> "INTEGER"
      is_boolean(self)  -> "BOOLEAN"
      is_atom(self)     -> "ATOM"
      is_binary(self)   -> "STRING"
      is_function(self) -> "FUNCTION"
      is_list(self)     -> "LIST"
      is_tuple(self)    -> "TUPLE"
      is_map(self)      -> "MAP"
      true              -> "MYSTERY TYPE"
    end
  end

  defp error(bool, data, schema) do
    data_type = typeof(data)
    if bool do
      :ok
    else
      {:error, ["Expected #{schema}, got #{data_type} #{inspect data}"]}
    end
  end

  defp validate_list(data, schema) do
    list_schema = Enum.reject(schema, &(&1 == :list))
    results = Enum.map(data, &(valid?(&1, list_schema)))
    |> Enum.reject(&(&1 == :ok))
    if Enum.count(results) == 0 do
      :ok
    else
      results
    end
  end

  defp validate_tuple(data, schema) do
    data_list = Tuple.to_list(data)
    schema_list = Tuple.to_list(schema)
    if Enum.count(data_list) == Enum.count(schema_list) do
      result = Enum.zip(data_list, schema_list)
      |> Enum.map(&(valid?(elem(&1, 0), elem(&1, 1))))
      |> Enum.reject(&(&1 == :ok))

      if (Enum.count(result) == 0), do: :ok, else: result
    else
      {:error, "Schema length doesn't match tuple length"}
    end
  end

  defp validate_map(data, schema) do
    data
    |> map_handler
    |> key_handler(schema)
    |> value_handler(schema)
  end

  defp map_handler(data) do
    if is_map(data) do
      data
    else
      {:error, "Data is not a map"}
    end
  end

  defp key_handler(data, schema) do
    case data do
      {:error, reason} -> {:error, reason}
      _ -> required_keys =
          schema
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
      {:error, "Missing required keys: #{inspect missing_keys}"}
    end
  end

  defp value_handler(data, schema) do
    case data do
      {:error, reason} -> {:error, reason}
      _ ->
        results = Enum.map(data, fn {k,v} -> valid?(v, schema[k]) end)
        |> Enum.filter(&(&1 != :ok))

        if Enum.count(results) == 0 do
          :ok
        else
          results
        end
    end
  end
end
