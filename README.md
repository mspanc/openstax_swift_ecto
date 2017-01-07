# OpenStax Swift Ecto integration
[![Build Status](https://travis-ci.org/mspanc/openstax_swift_ecto.svg?branch=master)](https://travis-ci.org/mspanc/openstax_swift_ecto)
[![Hex.pm](https://img.shields.io/hexpm/v/openstax_swift_ecto.svg)](https://hex.pm/packages/openstax_swift_ecto)
[![Hex.pm](https://img.shields.io/hexpm/dt/openstax_swift_ecto.svg)](https://hex.pm/packages/openstax_swift_ecto)
[![Donate via PayPal](https://img.shields.io/badge/Donate-PayPal-green.svg)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=RYXSPNFPM8ATU)
[![Donate via Beerpay](https://beerpay.io/mspanc/jumbo/badge.svg?style=flat)](https://beerpay.io/mspanc/openstax_swift_ecto)
[![Donate Bitcoins](https://img.shields.io/badge/Donate-Bitcoins-00feff.svg)](https://i.imgur.com/5VJeR9h.png)

OpenStax Swift Ecto eases using [OpenStack Swift](http://docs.openstack.org/developer/swift/api/object_api_v1_overview.html)
with Ecto models.


## Let me believe that Karma returns!

Developers are humans, too, we also need to pay bills from time to time. If you
wish to repay time and effort thay you have saved thanks to this piece of code,
you can click one of this nice, shiny buttons below:

| Paypal | Bitcoin | Beerpay |
| :----: | :-----: | :-----: |
| [![](https://www.paypalobjects.com/en_US/i/btn/btn_donateCC_LG.gif)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=RYXSPNFPM8ATU) | [![](https://i.imgur.com/dFkg3fw.png)](https://i.imgur.com/5VJeR9h.png)<br> 1LHsmP3odWxu1bzUfe2ydrewArB72XbN7n | [![Go to Beerpay](https://beerpay.io/mspanc/openstax_swift_ecto/badge.svg)](https://beerpay.io/mspanc/openstax_swift_ecto) |

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
