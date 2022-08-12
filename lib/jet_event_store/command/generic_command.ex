defmodule JetEventStore.Command.GenericCommand do
  @moduledoc """
  Define a commanded command.

  The `changeset` is stored in the `__changeset__` field of the command.

  Set required fields by module attribute '@required_fields'.
  Set tracked fields by module attribute '@tracked_fields'.

  ## Example

      defmodule MyCommand do
        use JetEventStore.Command.GenericCommand

        # Set required fields by module attribute '@required_fields'.
        @required_fields [:name]

        # Set tracked fields by module attribute '@tracked_fields'.
        @tracked_fields [:name]

        command_fields do
          field :name, :string
        end

        defimpl Validator do
          def validate(command) do
            command.__changeset__
            |> Ecto.Changeset.validate_length(:name, max: 255)
            |> case do
              %{valid?: true} -> {:ok, command}
              changeset -> {:error, changeset}
            end
          end
        end
      end
  """

  @type command() :: Ecto.Schema.schema()

  @doc "Build a command."
  @callback new(params :: map()) :: {:ok, command()} | {:error, Ecto.Changeset.t(command())}

  defmacro __using__(_opts) do
    Module.register_attribute(__CALLER__.module, :required_fields, accumulate: true)
    Module.register_attribute(__CALLER__.module, :tracked_fields, accumulate: true)

    quote location: :keep do
      @behaviour unquote(__MODULE__)
      @before_compile unquote(__MODULE__)

      use Ecto.Schema

      alias JetEventStore.Middleware.ValidateCommand.CommandValidator, as: Validator

      @timestamps_opts [type: :naive_datetime_usec]
      @primary_key false

      import unquote(__MODULE__), only: [command_fields: 1]

      @spec new!(map()) :: t()
      def new!(params) do
        case new(params) do
          {:ok, command} ->
            command

          error ->
            raise ArgumentError, """
            Fail to build the command (`#{inspect(__MODULE__)}`).
            params: #{inspect(params)}
            error: #{inspect(error)}
            """
        end
      end
    end
  end

  defmacro command_fields(do: block) do
    quote do
      embedded_schema do
        Module.eval_quoted(__MODULE__, unquote(block))

        field :__changeset__, :any, virtual: true
      end
    end
  end

  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  defmacro __before_compile__(_env) do
    required_fields = get_required_fields(__CALLER__.module)
    tracked_fields = get_tracked_fields(__CALLER__.module)

    quote location: :keep do
      unless Module.defines_type?(__MODULE__, {:t, 0}) do
        @type t() :: %__MODULE__{}
      end

      def __required_fields__, do: unquote(required_fields)
      def __tracked_fields__, do: unquote(tracked_fields)

      @spec build_changeset(params :: map()) :: Ecto.Changeset.t(t())
      defp build_changeset(params) do
        data = __struct__()
        permitted = __schema__(:fields)

        data
        |> Ecto.Changeset.cast(params, permitted)
        |> Ecto.Changeset.validate_required(unquote(required_fields))
      end

      @spec build_command(Ecto.Changeset.t(t())) ::
              {:ok, t()} | {:error, Ecto.Changeset.t(t())}
      defp build_command(%Ecto.Changeset{} = changeset) do
        case Ecto.Changeset.apply_action(changeset, :update) do
          {:ok, command} -> {:ok, %{command | __changeset__: changeset}}
          {:error, changeset} -> {:error, changeset}
        end
      end

      unless Module.defines?(__MODULE__, {:new, 1}, :def) do
        @impl unquote(__MODULE__)
        def new(params) do
          params
          |> build_changeset()
          |> build_command()
        end
      end
    end
  end

  @spec get_required_fields(module()) :: [atom()]
  defp get_required_fields(module) do
    module
    |> Module.get_attribute(:required_fields, [])
    |> List.flatten()
    |> Enum.uniq()
  end

  @spec get_tracked_fields(module()) :: [atom()]
  defp get_tracked_fields(module) do
    module
    |> Module.get_attribute(:tracked_fields, [])
    |> List.flatten()
    |> Enum.uniq()
  end
end
