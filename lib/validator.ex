defmodule Validator do
  require Logger
  def valid?(data, schema) do
    cond do
      Enum.member?(schema, :list) -> validate_list(data, schema)
      Enum.member?(schema, :map) -> nested_map(data, schema)
      is_map(schema) -> validate_map(data, schema)
      Enum.member?(schema, :string) -> is_binary(data) |> error("Not a String")
      Enum.member?(schema, :int) -> is_integer(data) |> error("Not an Integer")
      Enum.member?(schema, :any) -> :ok
      true -> {:error, "Your data is all jacked up"}
    end
  end

  defp nested_map(data, parent_schema) do
    schema = Enum.find(parent_schema, &is_function/1).()
    valid?(data, schema)
  end

  defp error(bool, error) do
    if bool do
      :ok
    else
      {:error, error}
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

  defp validate_map(data, schema) do
    result = data
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
