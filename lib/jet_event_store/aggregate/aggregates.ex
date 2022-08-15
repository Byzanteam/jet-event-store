defmodule JetEventStore.Aggregate.Aggregates do
  @moduledoc """
  Define an aggregate root.

  ## Options

  * `:aggregate_fetcher`(required: true) - an function that fetches aggregate state. The function
    accept two arguements aggregate name and uuid.
  * `:aggregates`(required: true) - a keyword list whose keys are aggregate names and values are
    aggregate modules.

  ## Example

  ```elixir
  defmodule BankAggregates do
    use JetEventStore.Aggregate.Aggregates,
      aggregate_fetcher: &__MODULE__.fetch_state/2,
      aggregates: [
        account: BankAccount
      ]

    @spec fetch_state(module(), String.t()) :: term()
    def fetch_state(module, identity) do
      Commanded.aggregate_state(Commanded.Application, module, identity)
    end
  end
  ```

  Then you can fetch aggregate state by `BankAggregates.fetch_account/1` or `BankAggregates.fetch_account!/1`.
  """

  @type uuid() :: Ecto.UUID.t()

  defmacro __using__(opts) do
    aggregate_fetcher = Keyword.fetch!(opts, :aggregate_fetcher)
    aggregates = Keyword.fetch!(opts, :aggregates)

    quote bind_quoted: [aggregate_fetcher: aggregate_fetcher, aggregates: aggregates],
          location: :keep do
      @aggregates Keyword.values(aggregates)

      @spec __aggregates__() :: list(module())
      def __aggregates__, do: @aggregates

      for {name, module} <- aggregates do
        @spec fetch(unquote(name), uuid :: JetEventStore.Aggregate.Aggregates.uuid()) ::
                {:ok, unquote(module).t()} | :error
        def fetch(unquote(name), uuid) do
          prev_trap_exit_flag = Process.flag(:trap_exit, false)
          module = unquote(module)
          [by: by, prefix: prefix] = module.__options__()

          try do
            state = apply(unquote(aggregate_fetcher), [module, prefix <> uuid])

            cond do
              is_atom(by) and is_struct(state, module) and Map.get(state, by) === uuid ->
                {:ok, state}

              is_function(by, 1) and is_struct(state, module) and by.(state) === uuid ->
                {:ok, state}

              true ->
                :error
            end
          after
            Process.flag(:trap_exit, prev_trap_exit_flag)
          end
        end

        @spec fetch!(unquote(name), uuid :: JetEventStore.Aggregate.Aggregates.uuid()) ::
                unquote(module).t()
        def fetch!(unquote(name), uuid) do
          name = unquote(name)

          case fetch(name, uuid) do
            {:ok, state} ->
              state

            :error ->
              raise RuntimeError, "can not find aggregate `#{inspect(name)}` by `#{uuid}`"
          end
        end

        fetcher = String.to_atom("fetch_#{name}")
        fetcher_bang = String.to_atom("fetch_#{name}!")

        @spec unquote(fetcher)(uuid :: JetEventStore.Aggregate.Aggregates.uuid()) ::
                {:ok, unquote(module).t()} | :error
        def unquote(fetcher)(uuid) do
          fetch(unquote(name), uuid)
        end

        @spec unquote(fetcher_bang)(uuid :: JetEventStore.Aggregate.Aggregates.uuid()) ::
                unquote(module).t()
        def unquote(fetcher_bang)(uuid) do
          fetch!(unquote(name), uuid)
        end
      end
    end
  end
end
