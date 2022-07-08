defmodule JetEventStore.Router do
  @moduledoc """
  Command routing macro that automatically sets lifespan option respectively.

  ## Options

  * `:aggregates`(required: true) - a list of aggregate modules

  ## Example

  ```elixir
  defmodule MyRouter do
    use JetEventStore.Router,
      aggregates: [BankAccount],
      application: Commanded.Application

    dispatch([Create], to: BankAccount)
  end
  ```
  """

  defmacro __using__(opts) do
    {aggregates, opts} = Keyword.pop!(opts, :aggregates)

    quote location: :keep do
      use Commanded.Commands.Router, unquote(opts)

      import unquote(__MODULE__), only: [route: 2]

      for aggregate <- unquote(aggregates) do
        identify(aggregate, aggregate.__options__())
      end
    end
  end

  defmacro route(commands, opts) do
    aggregate =
      opts
      |> Keyword.fetch!(:to)
      |> Macro.expand(__CALLER__)

    options =
      if is_lifespan?(aggregate) do
        [{:lifespan, aggregate} | opts]
      else
        opts
      end

    quote location: :keep do
      dispatch(unquote(commands), unquote(options))
    end
  end

  defp is_lifespan?(module) do
    :attributes
    |> module.__info__()
    |> Keyword.get_values(:behaviour)
    |> List.flatten()
    |> Enum.member?(Commanded.Aggregates.AggregateLifespan)
  end
end
