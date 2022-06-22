defmodule JetEventStore.EventCodec.ModuleCodec do
  @moduledoc """
  The behaviour to define the module-based codec for the event store.
  """

  @callback encode(term()) :: term()
  @callback decode(term()) :: term()
end
