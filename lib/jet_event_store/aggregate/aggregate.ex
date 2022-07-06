defmodule JetEventStore.Aggregate do
  @moduledoc """
  The `JetEventStore.Aggregate` behaviour is used to define an aggregate. An aggregate must
  implement `c:execute/2` and `c:apply/2` callbacks, both are described by Commanded guides.

  ## Options

  * `:by`(required: true) - aggregate identity field used by `identify` macro.
  * `:prefix`(required: true) - aggregate identity field used by `identify` macro.
  * `:lifespan`(default: false) - specify if lifespan behaviour should be implement.

  ## Example

  ```elixir
  defmodule BankAccount do
    use JetEventStore.Aggregate,
      by: :account_number,
      prefix: "bank-account-"

    defstruct [:account_number, balance: 0] 

    def execute(%__MODULE__{account_number: nil}, %Create{} = command) do
      %Created{
        account_number: command.account_number,
        balance: command.balance
      }
    end

    def apply(%__MODULE__{} = state, %Created{} = event) do
      %{state | account_number: event.account_number, balance: event.balance}
    end
  end
  ```
  """

  @required_keys [:by, :prefix]

  @typep state() :: struct()
  @typep command() :: struct()
  @typep event() :: struct()

  @callback execute(state(), command()) ::
              :ok | nil | event() | [event()] | {:ok, event() | [event()]} | {:error, term()}

  @callback apply(state(), event()) :: state()

  defmacro __using__(opts) do
    {lifespan, opts} = Keyword.pop(opts, :lifespan, false)

    unless ensure_required_keys?(opts) do
      raise CompileError, description: "aggregate must specify `by` and `prefix` options"
    end

    lifespan_behaviour =
      if lifespan do
        quote do: @behaviour(Commanded.Aggregates.AggregateLifespan)
      end

    quote location: :keep do
      @behaviour unquote(__MODULE__)
      unquote(lifespan_behaviour)

      @spec __options__() :: Keyword.t()
      def __options__, do: unquote(opts)
    end
  end

  defp ensure_required_keys?(opts) do
    Enum.all?(@required_keys, fn key ->
      case Keyword.get(opts, key) do
        nil -> false
        _otherwise -> true
      end
    end)
  end
end
