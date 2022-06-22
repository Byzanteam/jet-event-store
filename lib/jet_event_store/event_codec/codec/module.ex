defmodule JetEventStore.EventCodec.Codec.Module do
  @moduledoc """
  The module-based codec for events.

  ## Example:
  ```elixir
  defmodule MyEvent do
    @derive {
      JetEventStore.EventCodec,
      flag: {
        JetEventStore.EventCodec.Codec.Module,
        module: MyEctoType.Flag, encode: :to_string, decode: :from_string
      }
    }

    use TypedStruct

    typedstruct do
      field :flag, atom()
    end
  end
  ```
  """

  @behaviour JetEventStore.EventCodec.ParameterizedModuleCodec

  @impl true
  def encode(data, options) do
    module = Keyword.fetch!(options, :module)
    encode = Keyword.fetch!(options, :encode)

    apply(module, encode, [data])
  end

  @impl true
  def decode(data, options) do
    module = Keyword.fetch!(options, :module)
    decode = Keyword.fetch!(options, :decode)

    apply(module, decode, [data])
  end
end
