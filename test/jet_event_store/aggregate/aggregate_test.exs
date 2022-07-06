defmodule JetEventStore.Aggregate.AggregateTest do
  use ExUnit.Case, async: true

  defmodule MyAggregate do
    use JetEventStore.Aggregate,
      by: :aggregate_uuid,
      prefix: "aggregate-"

    @enforce_keys [:aggregate_uuid]
    defstruct [:aggregate_uuid]

    def execute(_state, _command), do: {:ok, []}
    def apply(state, _event), do: state
  end

  defmodule MyLifespanAggregate do
    use JetEventStore.Aggregate,
      by: :lifespan_aggregate_uuid,
      prefix: "lifespan-aggregate-",
      lifespan: true

    @aggregate_keepalive 5_000

    @enforce_keys [:lifespan_aggregate_uuid]
    defstruct [:lifespan_aggregate_uuid]

    def execute(_state, _command), do: {:ok, []}
    def apply(state, _event), do: state

    def after_command(_command), do: @aggregate_keepalive
    def after_event(_event), do: @aggregate_keepalive
    def after_error(_error), do: @aggregate_keepalive
  end

  test "normal aggregate" do
    assert fetch_behaviours(MyAggregate) === [JetEventStore.Aggregate]
    assert MyAggregate.__options__() === [by: :aggregate_uuid, prefix: "aggregate-"]
  end

  test "lifespan aggregate" do
    assert fetch_behaviours(MyLifespanAggregate) === [
             JetEventStore.Aggregate,
             Commanded.Aggregates.AggregateLifespan
           ]

    assert MyLifespanAggregate.__options__() === [
             by: :lifespan_aggregate_uuid,
             prefix: "lifespan-aggregate-"
           ]
  end

  defp fetch_behaviours(module) do
    :attributes
    |> module.__info__()
    |> Keyword.get_values(:behaviour)
    |> List.flatten()
  end
end
