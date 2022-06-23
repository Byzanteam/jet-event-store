defmodule JetEventStore.Command.Changes do
  @moduledoc """
  Handle changes occuring in a command.
  """

  @typep command() :: JetEventStore.Command.GenericCommand.command()
  @typep changes() :: %{atom() => term()}

  @doc """
  Fetch the `changes` from the command.

  All fields in the params may be treated as changed.
  """
  @spec fetch_changes(command()) :: changes()
  def fetch_changes(command) do
    tracked_fields = command.__struct__.__tracked_fields__()
    changeset = Map.fetch!(command, :__changeset__)

    fields =
      Enum.reduce(changeset.types, %{}, fn {key, _value}, acc ->
        acc
        |> Map.put(key, key)
        |> Map.put(Atom.to_string(key), key)
      end)

    Enum.reduce(changeset.params, %{}, fn {key, _value}, acc ->
      with(
        {:ok, field} <- Map.fetch(fields, key),
        true <- field in tracked_fields,
        {_source, value} <- Ecto.Changeset.fetch_field(changeset, field)
      ) do
        Map.put(acc, field, value)
      else
        _fallback -> acc
      end
    end)
  end

  @typep field_name() :: atom()
  @type event_change :: %{from: term(), to: term()}
  @type event_changes :: %{optional(field_name()) => event_change()}

  @spec build_event_changes(aggregate :: struct(), command()) :: event_changes()
  def build_event_changes(aggregate, command) when is_struct(aggregate) and is_struct(command) do
    command
    |> fetch_changes()
    |> Enum.reduce(%{}, fn {field, value}, acc ->
      case Map.fetch!(aggregate, field) do
        ^value ->
          acc

        value_was ->
          Map.put(acc, field, %{
            from: value_was,
            to: value
          })
      end
    end)
  end

  @doc """
  Loads previously dumped `data` into a changes.
  """
  @spec load_event_changes(schema :: module(), data :: map()) :: event_changes()
  def load_event_changes(schema, data) when is_map(data) do
    types = schema.__schema__(:load)

    Map.new(data, fn {field, change} ->
      field =
        case field do
          atom when is_atom(atom) -> atom
          str when is_binary(str) -> String.to_existing_atom(field)
        end

      type = Keyword.fetch!(types, field)

      from = load!(schema, field, type, indifferent_fetch!(change, :from))
      to = load!(schema, field, type, indifferent_fetch!(change, :to))

      {field, %{from: from, to: to}}
    end)
  end

  @compile {:inline, load!: 4}
  defp load!(schema, field, type, value) do
    case Ecto.Type.embedded_load(type, value, :json) do
      {:ok, value} ->
        value

      :error ->
        raise ArgumentError,
              "cannot load `#{inspect(value)}` as type #{inspect(type)} " <>
                "for field `#{field}`(#{inspect(schema)})."
    end
  end

  @doc """
  Dumps the given changes defined by an schema.
  """
  @spec dump_event_changes(schema :: module(), event_change()) :: map()
  def dump_event_changes(schema, changes) when is_map(changes) do
    types = schema.__schema__(:dump)

    Map.new(changes, fn {field, %{from: from, to: to}} ->
      {_source, type} = Map.fetch!(types, field)

      from = dump!(schema, field, type, from)
      to = dump!(schema, field, type, to)

      {field, %{from: from, to: to}}
    end)
  end

  @compile {:inline, dump!: 4}
  defp dump!(schema, field, type, value) do
    case Ecto.Type.embedded_dump(type, value, :json) do
      {:ok, value} ->
        value

      :error ->
        raise ArgumentError,
              "cannot dump `#{inspect(value)}` as type #{inspect(type)} " <>
                "for field `#{field}`(#{inspect(schema)})."
    end
  end

  @spec indifferent_fetch!(map(), key :: atom()) :: term()
  defp indifferent_fetch!(map, key) when is_atom(key) do
    case indifferent_fetch(map, key) do
      {:ok, value} -> value
      :error -> raise %KeyError{key: key, term: map}
    end
  end

  @spec indifferent_fetch(map(), key :: atom()) :: term()
  defp indifferent_fetch(map, key) when is_atom(key) do
    case Map.fetch(map, key) do
      {:ok, _value} = ok -> ok
      :error -> Map.fetch(map, Atom.to_string(key))
    end
  end
end
