defmodule Skooma.Validators do
  def min_length(min) do
    fn (data) ->
      bool = String.length(data) >= min
      if bool do
        :ok
      else
        {:error, "String must be longer than #{min} characters"}
      end
    end
  end

  def max_length(max) do
    fn (data) ->
      bool = String.length(data) <= max
      if bool do
        :ok
      else
        {:error, "String must be shorter than #{max} characters"}
      end
    end
  end

  def regex(regex) do
    fn (data) ->
      bool = Regex.match?(regex, data)
      if bool do
        :ok
      else
        {:error, "String does not match the regex pattern: #{inspect regex}"}
      end
    end
  end
end
