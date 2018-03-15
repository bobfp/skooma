defmodule Skooma.Basic do
  alias Skooma.Utils

  def validator(validator, type, data, schema, path \\ []) do
    data
    |> validator.()
    |> error(data, type, path)
    |> custom_validator(data, schema)
  end

  defp error(bool, data, expected_type, path) do
    if bool do
      {:success, data}
    else
      data_type = Utils.typeof(data)
      cond do
        Enum.count(path) > 0 -> {:failure, ["Expected #{expected_type}, got #{data_type} #{inspect data}, at #{eval_path path}"]}
        true -> {:failure, ["Expected #{expected_type}, got #{data_type} #{inspect data}"]}
      end
    end
  end

  defp eval_path(path) do
    Enum.join(path, " -> ")
  end

  defp custom_validator(result, data, schema) do
    case result do
      {:success, data} -> do_custom_validator(data, schema)
      _ -> result
    end
  end

  defp do_custom_validator(data, schema) do
    validators = Enum.filter(schema, &is_function/1)
    if Enum.count(validators) == 0 do
      {:success, data}
    else
      Enum.map(validators, &(&1.(data)))
      |> Enum.reject(&(&1 == :ok || &1 == true))
      |> Enum.map(&(if (&1 == false), do: {:failure, ["Value does not match custom validator"]}, else: &1))
    end
  end


end
