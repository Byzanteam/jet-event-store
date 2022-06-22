defmodule JetEventStore.EventCodec.Codec.NaiveDatetime do
  @moduledoc """
  The naive datetime codec for events.

  ## Example:
  ```elixir
  defmodule MyEvent do
    @derive {
      JetEventStore.EventCodec,
      inserted_at: JetEventStore.EventCodec.Codec.NaiveDatetime
    }

    use TypedStruct

    typedstruct do
      field :inserted_at, NaiveDateTime.t()
    end
  end
  ```
  """

  @behaviour JetEventStore.EventCodec.ModuleCodec

  @impl true
  def encode(data) do
    case Ecto.Type.dump(:naive_datetime_usec, data) do
      {:ok, dumped} ->
        dumped

      _error ->
        raise ArgumentError, "Can't encode NaiveDateTime: `#{inspect(data)}`"
    end
  end

  @impl true
  def decode(data) do
    case Ecto.Type.cast(:naive_datetime_usec, data) do
      {:ok, cast} ->
        cast

      _error ->
        raise ArgumentError, "Can't decode NaiveDateTime: `#{inspect(data)}`"
    end
  end
end
