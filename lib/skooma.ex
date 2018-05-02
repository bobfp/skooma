defmodule Skooma do
  alias Skooma.Utils
  alias Moonsugar.Validation, as: MV
  require Logger

  def validate(data, schema, path \\ []) do
    bv_partial = &(basic_validator(&1, data, schema, path))
    validation = cond do
      is_atom(schema) -> validate(data, [schema], path)
      is_map(schema) -> map_validator(data, schema, path)
      Keyword.keyword?(schema) -> keyword_validator(data, schema, path)
      Enum.member?(schema, :list) -> list_validator(data, schema, path)
      Enum.member?(schema, :bool) -> bv_partial.(&is_boolean/1)
      Enum.member?(schema, :string) -> bv_partial.(&is_binary/1)
      Enum.member?(schema, :int) -> bv_partial.(&is_integer/1)
      Enum.member?(schema, :float) -> bv_partial.(&is_float/1)
      Enum.member?(schema, :number) -> bv_partial.(&is_number/1)
      Enum.member?(schema, :atom) -> bv_partial.(&is_atom/1)
      Enum.member?(schema, :map) -> map_validator(data, schema, path)
    end
    case validation do
      {:success, _} -> {:success, data}
      failure -> failure
    end
  end

  defp basic_validator(validator, data, schema, path) do
    if validator.(data) do
      {:success, data}
    else
      basic_failure(data, schema, path)
    end
  end

  defp basic_failure(data, schema, path) do
    expected_type = schema
    |> List.first
    |> Atom.to_string
    |> String.upcase
    received_type = Utils.typeof(data)
    expected = "Expected #{expected_type}, "
    got = "got #{received_type} #{inspect(data)}"
    path_message = if Enum.count(path) > 0, do: ", at #{Enum.join(path, " -> ")}", else: ""
    reason = [expected <> got <> path_message]
    {:failure, reason}
  end

  defp map_validator(data, schema, path) do
    map_schema = case schema do
                   [:map, schema] -> schema
                   [:map, :not_required, schema] -> schema
                   schema -> schema
    end
    data
    |> MV.success()
    |> MV.concat(keys_validator(data, map_schema, path))
    |> MV.concat(values_validator(data, map_schema, path))
  end

  defp keys_validator(data, schema, path) do
    data_keys = Map.keys(data) |> MapSet.new
    schema_keys = Map.keys(schema) |> MapSet.new
    missing_keys = MapSet.difference(schema_keys, data_keys) |> MapSet.to_list
    if Enum.count(missing_keys) == 0 do
      {:success, data}
    else
      {:failure, ["Missing required keys: #{inspect(missing_keys)}"]}
    end
  end

  defp values_validator(data, schema, path) do
    Enum.map(schema, fn {k, v} -> validate(data[k], v, Enum.concat(path, [k])) end)
    |> MV.collect
  end

  defp list_validator([], _, _) do
    {:success, []}
  end

  defp list_validator(data, schema, path) do
    [_ | item_schema] = schema
    data
    |> Enum.with_index()
    |> Enum.map(fn ({v, i}) -> validate(v, item_schema, Enum.concat(path, ["index #{i}"])) end)
    |> MV.collect
  end

  defp keyword_validator(data, schema, path) do
    data_keys = Keyword.keys(data)
    schema_keys = Keyword.keys(schema)
    missing_keys = MapSet.difference(MapSet.new(schema_keys), MapSet.new(data_keys))
    if MapSet.size(missing_keys) == 0 do
      Enum.map(schema, fn{k, v} -> validate(data[k], v, Enum.concat(path, [k])) end)
      |> MV.collect
    end

  end

end
