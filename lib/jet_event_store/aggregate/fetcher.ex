defmodule JetEventStore.Aggregate.Fetcher do
  @moduledoc false

  @callback fetch_state(module(), uuid :: String.t()) :: {:ok, struct()} | :error
end
