defmodule JetEventStore.EventCodec.Codec.ListModule do
  @moduledoc """
  The module-based codec for list data.

  ## Example:
  ```elixir
  defmodule MyEvent do
    @derive {
      JetEventStore.EventCodec,
      flags: {
        JetEventStore.EventCodec.Codec.ListModule,
        module: MyEctoType.Flag, encode: :to_string, decode: :from_string
      }
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
  def encode(data, options) do
    module = Keyword.fetch!(options, :module)
    encode = Keyword.fetch!(options, :encode)

    Enum.map(data, fn item ->
      apply(module, encode, [item])
    end)
  end

  @impl true
  def decode(data, options) do
    module = Keyword.fetch!(options, :module)
    decode = Keyword.fetch!(options, :decode)

    Enum.map(data, fn item ->
      apply(module, decode, [item])
    end)
  end
end
