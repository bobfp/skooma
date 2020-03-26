defmodule Skooma.Validators do
  def min_length(min) do
    fn data ->
      bool = String.length(data) >= min

      if bool do
        :ok
      else
        {:error, "String must be longer than #{min} characters"}
      end
    end
  end

  def max_length(max) do
    fn data ->
      bool = String.length(data) <= max

      if bool do
        :ok
      else
        {:error, "String must be shorter than #{max} characters"}
      end
    end
  end

  def regex(regex) do
    fn data ->
      bool = Regex.match?(regex, data)

      if bool do
        :ok
      else
        {:error, "String does not match the regex pattern: #{inspect(regex)}"}
      end
    end
  end

  def inclusion(values_list) when is_list(values_list) do
    fn data ->
      bool = data in values_list

      if bool do
        :ok
      else
        {:error, "Value is not included in the options: #{inspect(values_list)}"}
      end
    end
  end

  def gt(value) do
    fn data ->
      bool = data > value

      if bool do
        :ok
      else
        {:error, "Value has to be greater than #{value}"}
      end
    end
  end

  def gte(value) do
    fn data ->
      bool = data >= value

      if bool do
        :ok
      else
        {:error, "Value has to be greater or equal than #{value}"}
      end
    end
  end

  def lt(value) do
    fn data ->
      bool = data < value

      if bool do
        :ok
      else
        {:error, "Value has to be less than #{value}"}
      end
    end
  end

  def lte(value) do
    fn data ->
      bool = data < value

      if bool do
        :ok
      else
        {:error, "Value has to be less or equal than #{value}"}
      end
    end
  end
end
