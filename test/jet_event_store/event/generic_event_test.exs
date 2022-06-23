defmodule JetEventStore.Event.GenericEventTest do
  use ExUnit.Case, async: true

  defmodule ExampleEvent do
    @moduledoc false

    use JetEventStore.Event.GenericEvent

    event_fields do
      field :uuid, Ecto.UUID.t()
    end
  end

  test "works" do
    assert %ExampleEvent{uuid: nil} === ExampleEvent.__struct__()
  end
end
