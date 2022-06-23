defprotocol JetEventStore.Middleware.ValidateCommand.CommandValidator do
  @moduledoc """
  The `CommandValidator` protocol used to validate a command.
  """

  alias JetEventStore.Command.GenericCommand

  @type t() :: GenericCommand.command()

  @fallback_to_any true

  @doc "Validate the command"
  @spec validate(t()) :: {:ok, t()} | {:error, Ecto.Changeset.t(t())}
  def validate(command)
end

defimpl JetEventStore.Middleware.ValidateCommand.CommandValidator, for: Any do
  @moduledoc false

  def validate(command), do: {:ok, command}
end
