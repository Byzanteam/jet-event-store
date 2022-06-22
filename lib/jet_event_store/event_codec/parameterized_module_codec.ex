defmodule JetEventStore.EventCodec.ParameterizedModuleCodec do
  @moduledoc """
  The behaviour to define the parameterized-module-based codec for the event store.
  """

  @callback encode(term(), options :: term()) :: term()
  @callback decode(term(), options :: term()) :: term()
end
