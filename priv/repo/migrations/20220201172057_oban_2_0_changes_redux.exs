defmodule Elixir.Pleroma.Repo.Migrations.Oban20ChangesRedux do
  use Ecto.Migration
  import Ecto.Query
  alias Pleroma.ConfigDB
  alias Pleroma.Repo

  def change do
    config_entry =
      from(c in ConfigDB, where: c.group == ^":pleroma" and c.key == ^"Oban")
      |> select([c], struct(c, [:value, :id]))
      |> Repo.one()

    if config_entry do
      %{value: value} = config_entry
      value =
        case Keyword.fetch(value, :log) do
          {:ok, log} -> Keyword.put(value, :log, false)
          _ -> value
        end

      Ecto.Changeset.change(config_entry, %{value: value})
      |> Repo.update()

    end
  end
end