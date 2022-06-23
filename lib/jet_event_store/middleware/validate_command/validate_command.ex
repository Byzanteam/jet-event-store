if Code.ensure_loaded?(Commanded) do
  defmodule JetEventStore.Middleware.ValidateCommand do
    @moduledoc """
    A `Commanded.Middleware` that validate the command using
    the `JetEventStore.Middleware.ValidateCommand.CommandValidator` protocol.
    """
    @behaviour Commanded.Middleware

    @dialyzer [:no_match]

    alias Commanded.Middleware.Pipeline

    @impl Commanded.Middleware
    def before_dispatch(%Pipeline{command: command} = pipeline) do
      alias JetEventStore.Middleware.ValidateCommand.CommandValidator

      case CommandValidator.validate(command) do
        {:ok, command} ->
          %{pipeline | command: command}

        {:error, _reason} = error ->
          pipeline
          |> Pipeline.respond(error)
          |> Pipeline.halt()
      end
    end

    @impl Commanded.Middleware
    def after_dispatch(pipeline), do: pipeline

    @impl Commanded.Middleware
    def after_failure(pipeline), do: pipeline
  end
end
