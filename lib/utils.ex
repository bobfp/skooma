defmodule Skooma.Utils do
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
end
