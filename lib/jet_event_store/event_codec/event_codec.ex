defprotocol JetEventStore.EventCodec do
  @moduledoc """
  Enrich or escape the event struct.

  ## Example

  ```elixir
  defmodule MyEvent do
    @derive {JetEventStore.EventCodec,
            [
              type: {&Atom.to_string/1, &String.to_existing_atom/1},
              inserted_at: {nil, &__MODULE__.decode_naive_datetime/1}
            ]}

    use TypedStruct

    typedstruct do
      field :type, atom()
      field :inserted_at, NaiveDateTime.t()
    end

    def decode_naive_datetime(%NaiveDateTime{} = dt), do: dt

    def decode_naive_datetime(dt_str) when is_binary(dt_str),
      do: NaiveDateTime.from_iso8601!(dt_str)
  end
  ```
  """

  @fallback_to_any true

  @doc """
  Encodes a event struct to a plain map that can be stored in the PG event_store.
  """
  @spec encode(struct()) :: map()
  def encode(data)

  @doc """
  Provides an extension point to allow additional decoding of the deserialized data.
  This can be used for parsing data into valid types, such as datetime parsing from a string.
  """
  @spec decode(map()) :: struct()
  def decode(data)
end

defimpl JetEventStore.EventCodec, for: Any do
  def encode(data), do: Map.from_struct(data)
  def decode(data), do: data

  defmacro __deriving__(module, _struct, options) do
    quote location: :keep do
      defimpl JetEventStore.EventCodec, for: unquote(module) do
        def encode(data) do
          Enum.reduce(
            unquote(options),
            Map.from_struct(data),
            fn
              {field, {mod, options}}, acc -> Map.update!(acc, field, &mod.encode(&1, options))
              {field, mod}, acc -> Map.update!(acc, field, &mod.encode/1)
            end
          )
        end

        def decode(data) do
          Enum.reduce(
            unquote(options),
            data,
            fn
              {field, {mod, options}}, acc -> Map.update!(acc, field, &mod.decode(&1, options))
              {field, mod}, acc -> Map.update!(acc, field, &mod.decode/1)
            end
          )
        end
      end
    end
  end
end
