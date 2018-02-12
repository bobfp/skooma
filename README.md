# Skooma

[![Hex.pm](https://img.shields.io/hexpm/v/skooma.svg)](https://hex.pm/packages/skooma)

> Simple data validation library for elixir.

Skooma was developed to be used to describe and validate the incoming and outgoing data structures from a REST API, but it can easily be used throughout a code base. No one likes writing data schemas, so the main focus during development was to develop an API that allowed for quick and simple schema creation.

## Table of Contents
- [Installation](#installation)
- [Overview](#overview)
- [Basics](#basics)
- [Complex Schemas](#complex-schemas)
- [Error Handling](#error-handling)
- [Validators](#validators)
- [Custom Validators](#custom-validators)
- [Contributions](#contributions)
- [License](#license)

## Installation

the package can be installed
by adding `skooma` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:skooma, "~> 0.2.0"}
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
  :race => :string,
  :name => :string,
  :level => :int,
  :gender => [:atom, :not_required]
  "potions" => [:list, :string],
}
Skooma.valid?(data, schema)
# :ok
```

## Basics

Skooma supports all of the elixir data types:

#### Boolean
```elixir
data = false
schema = :bool
Skooma.valid?(data, schema) #:ok
```

#### String
```elixir
data = "test"
schema = :string
Skooma.valid?(data, schema) #:ok
```

#### Integer
```elixir
data = 7
schema = :int
Skooma.valid?(data, schema) #:ok
```

#### Float
```elixir
data = 3.14
schema = :float
Skooma.valid?(data, schema) #:ok
```

#### Number
```elixir
data = 1.41
schema = :number
Skooma.valid?(data, schema) #:ok
```

#### Atom
```elixir
data = :thing
schema = :atom
Skooma.valid?(data, schema) #:ok
```

#### Map

```elixir
data = %{
  :race => "Khajiit",
  "level" => 6,
}
schema = %{
  :race => :string,
  "level" => :int,
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
schema = {:float, :float}
Skooma.valid?(data, schema) # :ok
```

#### Keyword List
```elixir
data = [key1: "value1", key2: 2, key3: :atom3]
schema = [key1: :string, key2: :int, key3: :atom]
Skooma.valid?(data, schema) # :ok
```

## Complex Schemas

#### Not Required
Sometimes, you want a field to be optional. In this case, use the `:not_required` atom.
```elixir
data = %{"key2" => 3}
schema = %{:key1 => [:string, :not_required], "key2" => :int}
Skooma.valid?(data, schema) # :ok
```
A nil value will also pass if `:not_required` is invoked
```elixir
data = %{:key1 => nil, "key2" => 3}
schema = %{:key1 => [:string, :not_required], "key2" => :int}
Skooma.valid?(data, schema) # :ok
```

#### Complex Maps
Skooma schemas can be nested and combined to match any data strucutre.
```elixir
my_hero = %{
  race: "Khajiit",
  stats: %{
    hp: 100,
    magicka: 60,
    xp: 5600
  }
}
schema = %{
  race: :string,
  stats: %{
    hp: :int,
    magicka: :int,
    xp: :int
  }
}
Skooma.valid?(data, schema) # :ok
```
For flexibilty and incase of recursive data structures, functions that return maps can also be used. In this case, the `:map` type must be explicitly used
```elixir
my_hero = %{
  name: "Alkosh"
  race: "Khajiit",
  friends: [ 
    %{name: "Asurah", race: "Khajiit"}, 
    %{name: "Carlos", race: "Dwarf"}
  ]
}

def hero_schema() do
  %{
    name: :string,
    race: :string,
    friends: [:list, :map, :not_required, &hero_schema/0]
   }
end
Skooma.valid?(my_hero, hero_schema) # :ok
```

#### Union Types
Skooma also lets you supply a list of schemas to allow for flexible data structures
```elixir
data1 = %{key1: "value1"}
data2 = 8

schema = [:union, [%{key1: :string}, :int]]

Skooma.valid?(data1, schema) # :ok
Skooma.valid?(data2, schema) # :ok
```

## Error Handling
If a the data and schema passed to `valid?/2` match, an `:ok` will be returned.

If a match isn't made, `valid?/2` returns something of the form `{:error, ["Error Mesasge 1", "Error Message 2"...])`

A few examples are:
```elixir
data = 7
schema = [:string]
Skooma.valid?(data, schema) # {:error, ["Expected STRING, got INTEGER 7"]}
```
```elixir
data = %{
  :key1 => "value1",
  "key2" => %{color: "blue"},
  "things" => ["thing1", 5],
  "stuff" => %{key3: %{key4: 9}}
}
schema = %{
  :key1 => [:string],
  "key2" => [:map, %{color: [:string]}],
  "things" => [:list, :string],
  "stuff" => %{key3: %{key4: [:string]}}
}
Skooma.valid?(data, schema) # => 
# {:error, [
#  "Expected STRING, got INTEGER 9, at stuff -> key3 -> key4",
#  "Expected STRING, got INTEGER 5, at things -> index 1"
# ]}
```

## Validators
Skooma comes with a few additional functions that can be used to perform more complex validation.
```elixir
data = "abc"
schema = [:string, Validators.min_length(4)]
Skooma.valid?{data, schema) # {:error, ["String must be longer than 4 characters"]}
```

Multiple validators can also be used at the same time:
```elixir
data = "duck"
schema = [:string, Validators.regex(~r/foo/), Validators.max_length(5)]
Skooma.valid?{data, schema) # {:error, ["String does not match the regex pattern: ~r/foo/"]}
```

## Custom Validators
There is nothing special about the validator functions that Skooma comes with. Making your own is super easy.

There are two types of custom validators. The most barebones is any function that accepts one argument and returns a boolean:
```elixir
data = 8
schema = [:int, &(&1 == 0)]
Skooma.valid?{data, schema) # {:error, ["Value does not match custom validator"]}
```

However, if you need more flexibility or a custom error message, instead of returning a boolean, your function should return either `:ok` or `{:error, "Your Custom Error Message"}`. Take the built it max_length validator as an example:
```elixir
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

data = "abcdefghijk"
schema = [:string, Validators.max_length(7)]
Skooma.valid?{data, schema) # {:error, ["String must be shorter than 7 characters"]}
```

## Contributions
All contributions are welcome. If there is a validator you would like to see added to the library, please create an issue!

## License

[MIT](LICENSE) &copy; bcoop713