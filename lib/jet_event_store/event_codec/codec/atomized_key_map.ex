defmodule JetEventStore.EventCodec.Codec.AtomizedKeyMap do
  @moduledoc """
  Atomize root keys of the event data.

  ## Example:

  ```elixir
  defmodule MyEvent do
    @derive {
      JetEventStore.EventCodec,
      settings: JetEventStore.EventCodec.Codec.AtomizedKeyMap
    }

    use TypedStruct

    typedstruct do
      field :settings, map()
    end
  end
  ```
  """

  @behaviour JetEventStore.EventCodec.ModuleCodec

  @impl true
  def encode(data) when is_map(data) do
    data
  end

  @impl true
  def decode(data) when is_map(data) do
    atomize_keys!(data)
  end

  defp atomize_keys!(struct) when is_struct(struct), do: struct

  defp atomize_keys!(map) when is_map(map) do
    Map.new(map, fn
      {str_key, value} when is_binary(str_key) -> {String.to_existing_atom(str_key), value}
      {atom_key, value} when is_atom(atom_key) -> {atom_key, value}
      {key, _value} -> raise RuntimeError, "Unable to atomize key: #{key}"
    end)
  end
end
