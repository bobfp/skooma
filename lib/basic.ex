defmodule Skooma.Basic do
  alias Skooma.Utils

  def validator(validator, type, data, schema, path \\ []) do
    data
    |> validator.()
    |> error(data, type, path)
    |> custom_validator(data, schema)
  end

  defp error(bool, data, expected_type, path) do
    data_type = Utils.typeof(data)
    if bool do
      :ok
    else
      cond do
        Enum.count(path) > 0 -> {:error, "Expected #{expected_type}, got #{data_type} #{inspect data}, at #{eval_path path}"}
        true -> {:error, "Expected #{expected_type}, got #{data_type} #{inspect data}"}
      end
    end
  end

  defp eval_path(path) do
    Enum.join(path, " -> ")
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
      Enum.map(validators, &(&1.(data)))
      |> Enum.reject(&(&1 == :ok || &1 == true))
      |> Enum.map(&(if (&1 == false), do: {:error, "Value does not match custom validator"}, else: &1))
    end
  end


end
