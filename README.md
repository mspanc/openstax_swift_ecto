# OpenStax Swift Ecto integration
[![Build Status](https://travis-ci.org/mspanc/openstax_swift_ecto.svg?branch=master)](https://travis-ci.org/mspanc/openstax_swift_ecto)
[![Hex.pm](https://img.shields.io/hexpm/v/openstax_swift_ecto.svg)](https://hex.pm/packages/openstax_swift_ecto)
[![Hex.pm](https://img.shields.io/hexpm/dt/openstax_swift_ecto.svg)](https://hex.pm/packages/openstax_swift_ecto)

OpenStax Swift Ecto eases using [OpenStack Swift](http://docs.openstack.org/developer/swift/api/object_api_v1_overview.html)
with Ecto models.


## Status

Project in the early stage of development. API may change without prior warning.

# Introduction

This module simplifies using OpenStax Swift storage with Ecto Models.

It exposes several functions that allow to easily upload/download files
that should be logically bound to certain record.

It automatically performs MIME type checks and ensures that uploaded
files have right MIME type in the storage.

By design, only one file per record is allowed.

If either `file_type` or `file_size`, `file_etag`, `file_name` fields will
be present in the model it will be automatically updated. Names of these
fields can be overriden by overriding `swift_file_size_field`,
`swift_file_type_field`, `swift_file_etag_field` and `swift_file_name_field`
functions. Override this to functions that return `nil` to disable that feature.

An example model that uses `OpenStax.Swift.Ecto.Model`:

```elixir
defmodule MyApp.MyModel do
  use Ecto.Model
  use OpenStax.Swift.Ecto.Model

  @required_fields ~w()
  @optional_fields ~w(file_size file_type file_etag file_name)

  schema "mymodel" do
    field :file_size, :integer
    field :file_type, :string
    field :file_etag, :string
    field :file_name, :string
    timestamps
  end

  def swift_endpoint_id(_record), do: :myendpoint
  def swift_container(_record),   do: :somecontainer
  def swift_object_id(record),    do: "something_" <> record.id

  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
  end
end
```

An example usage:

```elixir
defmodule MyApp.MyLogic do
  def attach_file_to_record(record_id, path) do
    record = MyApp.Repo.get!(MyApp.MyModel, record_id)

    case OpenStax.Swift.Ecto.Model.upload(MyApp.Repo, record, {:file, path}) do
      {:ok, record} ->
        IO.puts "OK " <> OpenStax.Swift.Ecto.Model.temp_url(record)

      {:error, reason} ->
        IO.puts "ERROR " <> inspect(reason)
    end
  end
end
```

# Authors

Marcin Lewandowski <marcin@saepia.net>

# License

MIT
