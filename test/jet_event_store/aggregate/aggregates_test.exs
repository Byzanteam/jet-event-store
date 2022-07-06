defmodule JetEventStore.Aggregate.AggregatesTest do
  use ExUnit.Case, async: true

  alias __MODULE__

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

  defmodule MyAggregates do
    use JetEventStore.Aggregate.Aggregates,
      aggregate_fetcher: &AggregatesTest.fetch_state/2,
      aggregates: [
        my_aggregate: MyAggregate,
        my_lifespan_aggregate: MyLifespanAggregate
      ]
  end

  describe "aggregates" do
    test "__aggregates__/0" do
      assert MyAggregates.__aggregates__() === [MyAggregate, MyLifespanAggregate]
    end
  end

  describe "aggregate fetcher" do
    test "fetch/2" do
      assert {:ok, %MyAggregate{}} = MyAggregates.fetch(:my_aggregate, "exists")

      assert {:ok, %MyLifespanAggregate{}} = MyAggregates.fetch(:my_lifespan_aggregate, "exists")

      assert :error = MyAggregates.fetch(:my_aggregate, "void")
      assert :error = MyAggregates.fetch(:my_lifespan_aggregate, "void")
    end

    test "fetch!/2" do
      assert %MyAggregate{} = MyAggregates.fetch!(:my_aggregate, "exists")

      assert %MyLifespanAggregate{} = MyAggregates.fetch!(:my_lifespan_aggregate, "exists")

      assert_raise(RuntimeError, "can not find aggregate `:my_aggregate` by `void`", fn ->
        MyAggregates.fetch!(:my_aggregate, "void")
      end)

      assert_raise(
        RuntimeError,
        "can not find aggregate `:my_lifespan_aggregate` by `void`",
        fn ->
          MyAggregates.fetch!(:my_lifespan_aggregate, "void")
        end
      )
    end

    test "fetch_my_aggregate/1 and fetch_my_aggregate!/1" do
      assert {:ok, %MyAggregate{}} = MyAggregates.fetch_my_aggregate("exists")
      assert :error = MyAggregates.fetch_my_aggregate("void")
      assert %MyAggregate{} = MyAggregates.fetch_my_aggregate!("exists")

      assert_raise(RuntimeError, "can not find aggregate `:my_aggregate` by `void`", fn ->
        MyAggregates.fetch_my_aggregate!("void")
      end)
    end

    test "fetch_my_lifespan_aggregate/1 and fetch_my_lifespan_aggregate!/1" do
      assert {:ok, %MyLifespanAggregate{}} = MyAggregates.fetch_my_lifespan_aggregate("exists")
      assert :error = MyAggregates.fetch_my_lifespan_aggregate("void")
      assert %MyLifespanAggregate{} = MyAggregates.fetch_my_lifespan_aggregate!("exists")

      assert_raise(
        RuntimeError,
        "can not find aggregate `:my_lifespan_aggregate` by `void`",
        fn ->
          MyAggregates.fetch_my_lifespan_aggregate!("void")
        end
      )
    end
  end

  def fetch_state(MyAggregate, "aggregate-exists") do
    %MyAggregate{aggregate_uuid: "exists"}
  end

  def fetch_state(MyAggregate, _uuid) do
    nil
  end

  def fetch_state(MyLifespanAggregate, "lifespan-aggregate-exists") do
    %MyLifespanAggregate{lifespan_aggregate_uuid: "exists"}
  end

  def fetch_state(MyLifespanAggregate, _uuid) do
    nil
  end
end
