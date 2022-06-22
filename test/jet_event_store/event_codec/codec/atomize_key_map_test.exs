defmodule JetEventStore.EventCodec.Codec.AtomizeKeyMapTest do
  use ExUnit.Case, async: true

  alias JetEventStore.EventCodec.Codec.AtomizedKeyMap

  describe "decode/1" do
    test "works" do
      map = %{"foo" => "bar", :baz => "qux"}

      assert %{foo: "bar", baz: "qux"} === AtomizedKeyMap.decode(map)
    end

    test "atomize the root level keys" do
      map = %{"foo" => %{"baz" => "qux"}}

      assert %{foo: %{"baz" => "qux"}} === AtomizedKeyMap.decode(map)
    end

    test "raises error when the key is neither a string nor an atom" do
      map = %{1 => %{"baz" => "qux"}}

      assert_raise(RuntimeError, ~r/Unable to atomize key/, fn ->
        AtomizedKeyMap.decode(map)
      end)
    end
  end
end
