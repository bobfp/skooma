# Skooma

Skooma is a simple data validation library for elixir. Skooma was developed to be used to describe and validate the incoming and outgoing data structures from a REST API, but it can easily be used throughout a code base. No one likes writing data schemas, so the main focus during development was to develop an API that allowed for quick and simple schema creation.



## Installation

the package can be installed
by adding `skooma` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:skooma, "~> 0.1.0"}
  ]
end
```

## Overview

Skooma exposes the function `valid?/2` 

```elixir
data = %{
  :race => "Khajiit",
  :name => "Bob",
  :level => 6,
  "potions" => ["Skooma", "Fortify Health", "Fortify Magicka"]
  
}
schema = %{
  :race => [:string],
  :name => [:string],
  :level => [:int],
  :gender => [:atom, :not_required]
  "potion" => [:list, :string],
}
Skooma.valid?(data, schema)
# :ok
```

## Basics

Skooma supports all of the elixir data types:

#### Boolean
```elixir
data = false
schema = [:bool]
Skooma.valid?(data, schema) #:ok
```

#### String
```elixir
data = "test"
schema = [:string]
Skooma.valid?(data, schema) #:ok
```

#### Integer
```elixir
data = 7
schema = [:int]
Skooma.valid?(data, schema) #:ok
```

#### Float
```elixir
data = 3.14
schema = [:float]
Skooma.valid?(data, schema) #:ok
```

#### Number
```elixir
data = 1.41
schema = [:number]
Skooma.valid?(data, schema) #:ok
```

#### Atom
```elixir
data = :thing
schema = [:atom]
Skooma.valid?(data, schema) #:ok
```

#### Map

```elixir
data = %{
  :race => "Khajiit",
  "level" => 6,
}
schema = %{
  :race => [:string],
  "level" => [:int],
}
Skooma.valid?(data, schema) # :ok

```

#### List
```elixir
data = [1, 2, 3]
schema = [:list, :int]
Skooma.valid?(data, schema) # :ok
```

#### Tuple
```elixir
data = {456.89, 365.65}
schema = {[:float], [:float]}
Skooma.valid?(data, schema) # :ok
```

#### Keyword List
```elixir
data = [key1: "value1", key2: 2, key3: :atom3]
schema = [key1: [:string], key2: [:int], key3: [:atom]]
Skooma.valid?(data, schema) # :ok
```

## Complex Schemas