defmodule JetEventStore.Command.ChangesTest do
  use ExUnit.Case, async: true

  alias JetEventStore.Command.Changes

  defmodule MyAtom do
    @moduledoc false

    use Ecto.Type

    @impl true
    def embed_as(_format), do: :dump

    @impl true
    def type, do: :string

    @impl true
    def cast(atom) when is_atom(atom), do: {:ok, atom}
    def cast(str) when is_binary(str), do: {:ok, String.to_atom(str)}
    def cast(_), do: :error

    @impl true
    def load(nil), do: {:ok, nil}
    def load(data) when is_binary(data), do: {:ok, String.to_atom(data)}
    def load(_data), do: :error

    @impl true
    def dump(nil), do: {:ok, nil}
    def dump(atom) when is_atom(atom), do: {:ok, Atom.to_string(atom)}
    def dump(_data), do: :error
  end

  defmodule DummyCommand do
    @moduledoc false

    use JetEventStore.Command.GenericCommand

    @required_fields [:uuid]
    @tracked_fields [:name, :flag]

    command_fields do
      field :uuid, Ecto.UUID
      field :name, :string
      field :flag, MyAtom
    end
  end

  defmodule DummyAggregate do
    @moduledoc false
    use TypedStruct

    typedstruct do
      field :uuid, Ecto.UUID.t()
      field :name, String.t()
      field :flag, atom()
    end
  end

  describe "fetch_changes/1" do
    test "works" do
      uuid = Ecto.UUID.generate()

      assert %{} === fetch_changes(%{uuid: uuid})

      assert %{name: "Mark"} === fetch_changes(%{uuid: uuid, name: "Mark"})
      assert %{name: "Mark"} === fetch_changes(%{"uuid" => uuid, "name" => "Mark"})

      assert %{name: nil} === fetch_changes(%{uuid: uuid, name: nil})
      assert %{name: nil} === fetch_changes(%{"uuid" => uuid, "name" => nil})
    end
  end

  describe "build_event_changes/2" do
    test "works" do
      uuid = Ecto.UUID.generate()

      aggregate = %DummyAggregate{uuid: uuid, name: "Mark"}

      assert %{name: %{from: "Mark", to: nil}} ===
               build_event_changes(aggregate, %{"uuid" => uuid, "name" => nil})

      assert %{name: %{from: "Mark", to: "Max"}} ===
               build_event_changes(aggregate, %{"uuid" => uuid, "name" => "Max"})

      assert %{} ===
               build_event_changes(%{aggregate | flag: :foo}, %{"uuid" => uuid, "flag" => :foo})
    end
  end

  describe "load_event_changes/2" do
    test "works" do
      uuid = Ecto.UUID.generate()

      assert %{
               uuid: %{from: nil, to: uuid},
               flag: %{from: nil, to: :foo}
             } ===
               Changes.load_event_changes(
                 DummyCommand,
                 %{
                   "uuid" => %{"from" => nil, "to" => uuid},
                   "flag" => %{"from" => nil, "to" => "foo"}
                 }
               )

      assert %{
               uuid: %{from: nil, to: uuid},
               flag: %{from: nil, to: :foo}
             } ===
               Changes.load_event_changes(
                 DummyCommand,
                 %{
                   uuid: %{from: nil, to: uuid},
                   flag: %{from: nil, to: "foo"}
                 }
               )

      assert %{} ===
               Changes.load_event_changes(
                 DummyCommand,
                 %{}
               )

      assert_raise KeyError, fn ->
        Changes.load_event_changes(
          DummyCommand,
          %{
            "unknown" => %{"from" => nil, "to" => "foo"}
          }
        )
      end

      assert_raise KeyError, fn ->
        Changes.load_event_changes(
          DummyCommand,
          %{
            "flag" => %{"from" => nil}
          }
        )
      end

      assert_raise ArgumentError, fn ->
        Changes.load_event_changes(
          DummyCommand,
          %{
            "flag" => %{"from" => nil, "to" => 1}
          }
        )
      end
    end
  end

  describe "dump_event_changes/2" do
    test "works" do
      uuid = Ecto.UUID.generate()

      assert %{
               uuid: %{from: nil, to: uuid},
               flag: %{from: nil, to: "foo"}
             } ===
               Changes.dump_event_changes(
                 DummyCommand,
                 %{
                   uuid: %{from: nil, to: uuid},
                   flag: %{from: nil, to: :foo}
                 }
               )

      assert %{} ===
               Changes.dump_event_changes(
                 DummyCommand,
                 %{}
               )

      assert_raise KeyError, fn ->
        Changes.dump_event_changes(
          DummyCommand,
          %{
            unknown: %{from: nil, to: :foo}
          }
        )
      end

      assert_raise ArgumentError, fn ->
        Changes.dump_event_changes(
          DummyCommand,
          %{
            flag: %{from: nil, to: 1}
          }
        )
      end
    end
  end

  defp fetch_changes(params) do
    Changes.fetch_changes(DummyCommand.new!(params))
  end

  defp build_event_changes(aggregate, params) do
    Changes.build_event_changes(aggregate, DummyCommand.new!(params))
  end
end
