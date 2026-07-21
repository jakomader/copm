defmodule Copm.Kafka.Actualize do
  @moduledoc false

  alias Ecto.Changeset

  @doc "Ключи payload, отсутствующие среди known_camel_keys — вероятные опечатки в названии поля."
  def unknown_fields(payload, known_camel_keys) do
    payload
    |> Map.keys()
    |> Enum.reject(&(&1 in known_camel_keys))
  end

  @doc "Готовый changeset-error для неизвестных полей, в форме, ожидаемой consumer'ами (`{:error, changeset}`)."
  def reject_unknown_fields(struct, extra) do
    struct
    |> Changeset.change()
    |> Changeset.add_error(:base, "неожиданные поля: #{inspect(extra)}")
    |> then(&{:error, &1})
  end
end
