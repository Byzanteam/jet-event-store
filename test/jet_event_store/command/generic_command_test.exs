defmodule JetEventStore.Command.GenericCommandTest do
  use ExUnit.Case, async: true

  defmodule DummyCommand do
    @moduledoc false

    use JetEventStore.Command.GenericCommand

    @required_fields [:uuid, :name]
    @tracked_fields [:name]

    command_fields do
      field :uuid, Ecto.UUID
      field :name, :string
    end
  end

  defmodule MyCommand do
    @moduledoc false

    use JetEventStore.Command.GenericCommand

    @required_fields [:uuid, :name]
    @tracked_fields [:name]

    command_fields do
      field :uuid, Ecto.UUID
      field :name, :string
    end

    @impl true
    def new(params) do
      params
      |> build_changeset()
      |> Ecto.Changeset.validate_format(:name, ~r/^[a-z]+$/)
      |> build_command()
    end
  end

  describe "new/1" do
    test "works" do
      uuid = Ecto.UUID.generate()

      assert match?(
               {:error,
                %Ecto.Changeset{
                  valid?: false,
                  errors: [name: {"can't be blank", [validation: :required]}]
                }},
               DummyCommand.new(%{uuid: uuid, name: nil})
             )

      assert {:ok, command} = DummyCommand.new(%{uuid: uuid, name: "Mark"})
      assert command.__changeset__.valid?
    end

    test "overwrites" do
      uuid = Ecto.UUID.generate()

      assert match?(
               {:error,
                %Ecto.Changeset{
                  valid?: false,
                  errors: [name: {"has invalid format", [validation: :format]}]
                }},
               MyCommand.new(%{uuid: uuid, name: "Mark"})
             )

      assert {:ok, command} = MyCommand.new(%{uuid: uuid, name: "mark"})
      assert command.__changeset__.valid?
    end
  end
end
