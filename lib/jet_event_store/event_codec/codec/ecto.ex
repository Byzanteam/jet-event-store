defmodule JetEventStore.EventCodec.Codec.Ecto do
  @moduledoc """
  Use Ecto style codec to encode and decode events.

  ## Example:
  ```elixir
  defmodule MyEvent do
    @derive {
      JetEventStore.EventCodec,
      flags: {JetEventStore.EventCodec.Codec.Ecto, {:array, MyEctoTypes.Atom}}
    }

    use TypedStruct

    typedstruct do
      field :flags, [atom()]
    end
  end
  ```
  """

  @behaviour JetEventStore.EventCodec.ParameterizedModuleCodec

  @impl true
  def encode(data, type) do
    case Ecto.Type.dump(type, data) do
      {:ok, dumped} ->
        dumped

      _error ->
        raise ArgumentError, "Can't encode `#{inspect(data)}` to the `#{inspect(type)}` type."
    end
  end

  @impl true
  def decode(data, type) do
    case Ecto.Type.load(type, data) do
      {:ok, loaded} ->
        loaded

      _error ->
        raise ArgumentError, "Can't decode `#{inspect(data)}` as the `#{inspect(type)}` type."
    end
  end
end
