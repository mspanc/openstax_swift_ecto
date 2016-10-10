defmodule OpenStax.Swift.Ecto.Model do
  @moduledoc """
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

  An example usage:

      defmodule MyApp.MyLogic do
        def store_model(id, file) do
          record = MyApp.Repo.get!(MyApp.MyModel, 123)

          case OpenStax.Swift.Ecto.Model.upload(record, file) do
            :ok ->
              IO.puts "OK"

            {:error, reason} ->
              IO.puts "ERROR " <> inspect(reason)
          end
        end
      end
  """


  @doc """
  Returns string that contains Swift Object ID for given record.

  Default implementation takes passed struct type and adds value of the `id`
  field of the struct, concatenated using underscore.
  """
  @callback swift_object_id(map) :: String.t


  @doc """
  Returns OpenStax Swift endpoint ID as atom for given record.

  Endpoint has to be previously configures, please refer to OpenStax Swift
  documentation to see how to do it.
  """
  @callback swift_endpoint_id(map) :: atom


  @doc """
  Returns container name as atom or string for given record.
  """
  @callback swift_container(map) :: atom | String.t


  @doc """
  Returns field name that should contain file size for given record.

  Return nil if you want to disable this feature.
  """
  @callback swift_file_size_field(map) :: atom | nil


  @doc """
  Returns field name that should contain file type for given record.

  Return nil if you want to disable this feature.
  """
  @callback swift_file_type_field(map) :: atom | nil


  @doc """
  Returns field name that should contain file type for given record.

  Return nil if you want to disable this feature.
  """
  @callback swift_file_etag_field(map) :: atom | nil


  @doc """
  Returns field name that should contain file name for given record.

  Return nil if you want to disable this feature.
  """
  @callback swift_file_name_field(map) :: atom | nil


  defmacro __using__(_) do
    quote location: :keep do
      @behaviour OpenStax.Swift.Ecto.Model

      # Default implementations

      @doc false
      def swift_object_id(record) do
        # When we serialize __struct__, "Elixir." prefix is added,
        # we want to remove it.
        prefix = to_string(record.__struct__) |> String.split(".", parts: 2) |> List.last
        suffix = to_string(record.id)

        prefix <> "_" <> suffix
      end


      @doc false
      def swift_file_size_field(_record), do: :file_size


      @doc false
      def swift_file_type_field(_record), do: :file_type


      @doc false
      def swift_file_etag_field(_record), do: :file_etag


      @doc false
      def swift_file_name_field(_record), do: :file_name


      defoverridable [
        swift_object_id: 1,
        swift_file_type_field: 1,
        swift_file_size_field: 1,
        swift_file_etag_field: 1,
        swift_file_name_field: 1,
      ]
    end
  end


  @doc """
  Synchronously uploads file from given path to the storage and associates
  it with given record using given repo.

  If either `file_type` or `file_size`, `file_etag`, `file_name` fields will
  be present in the model it will be automatically updated. Names of these
  fields can be overriden by overriding `swift_file_size_field`,
  `swift_file_type_field`, `swift_file_etag_field` and `swift_file_name_field`
  functions. Override this to functions that return `nil` to disable that feature.

  It creates single Object in the storage.

  First argument is a repo to use while updating the record.

  Second argument is a record that is supposed to be "an owner" of the file.

  Third argument is a path to the file.

  On success it returns `{:ok, record}`.

  On failure to communicate with the storage it returns
  `{:error, {:storage, reason}}`.

  On failure to update the record it returns `{:error, {:update, changeset}}`.
  """
  @spec upload(Ecto.Repo.t, map, String.t) :: {:ok, map} | {:error, any}
  def upload(repo, record, file_path) when is_binary(file_path) and is_map(record) do
    # Get MIME type
    mime_result = FileInfo.get_info(file_path)[file_path]
    %FileInfo.Mime{subtype: mime_subtype, type: mime_type} = mime_result
    file_type = mime_type <> "/" <> mime_subtype

    # Get file size
    %File.Stat{size: file_size} = File.stat!(file_path)

    # Upload the file
    object_id = record.__struct__.swift_object_id(record)
    endpoint_id = record.__struct__.swift_endpoint_id(record)
    container = record.__struct__.swift_container(record)

    # FIXME use file as contents
    # FIXME set name -> change openstax swift lib
    # FIXME set content type -> change openstax swift lib
    case OpenStax.Swift.API.Object.create(endpoint_id, container, object_id, "") do
      {:ok, %{etag: file_etag}} ->
        # Update record
        file_type_field = record.__struct__.swift_file_type_field(record)
        file_size_field = record.__struct__.swift_file_size_field(record)
        file_etag_field = record.__struct__.swift_file_etag_field(record)

        changeset = record.__struct__.changeset(record)

        changeset = if Map.has_key?(record, file_type_field) do
          changeset |> Ecto.Changeset.put_change(file_type_field, file_type)
        else
          changeset
        end

        changeset = if Map.has_key?(record, file_size_field) do
          changeset |> Ecto.Changeset.put_change(file_size_field, file_size)
        else
          changeset
        end

        changeset = if Map.has_key?(record, file_etag_field) do
          changeset |> Ecto.Changeset.put_change(file_etag_field, file_etag)
        else
          changeset
        end

        case repo.update(changeset) do
          {:ok, record}       -> {:ok, record}
          {:error, changeset} -> {:error, {:update, changeset}}
        end

      {:error, reason} ->
        {:error, {:storage, reason}}
    end
  end


  @doc """
  Does the same as `upload/3` but throws an error in case of failure.
  """
  @spec upload!(Ecto.Repo.t, map, String.t) :: map
  def upload!(repo, record, file_path) when is_binary(file_path) and is_map(record) do
    case upload(repo, record, file_path) do
      {:ok, record}    -> record
      {:error, reason} -> throw reason # FIXME should I use raise or throw?
    end
  end
end
