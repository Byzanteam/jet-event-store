defmodule JetEventStore.Event.GenericEvent do
  @moduledoc """
  Defines a commanded event.

  ## Example

  ```elixir
  defmodule ExampleEvent do
    @moduledoc false

    use JetEventStore.Event.GenericEvent

    event_fields do
      field :uuid, Ecto.UUID.t()
    end
  end
  ```

  equals to the below:


  ```elixir
  defmodule ExampleEvent do
    @moduledoc false

    use TypedStruct

    typedstruct enforce: true do
      field :uuid, Ecto.UUID.t()
    end
  end
  ```
  """

  defmacro __using__(_opts) do
    quote do
      use TypedStruct

      import unquote(__MODULE__)
    end
  end

  defmacro event_fields(do: block) do
    quote do
      typedstruct enforce: true do
        Module.eval_quoted(__MODULE__, unquote(block))
      end
    end
  end
end
