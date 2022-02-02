defmodule Elixir.Pleroma.Repo.Migrations.Oban20ChangesRedux do
  use Ecto.Migration
  import Ecto.Query
  alias Pleroma.ConfigDB
  alias Pleroma.Repo

  require Logger

  def change do
    config_entry =
      from(c in ConfigDB, where: c.group == ^":pleroma" and c.key == ^"Oban")
      |> select([c], struct(c, [:value, :id]))
      |> Repo.one()

    if config_entry do
      %{value: value} = config_entry

      # Logger.info(
      #   "Found Oban config entry: #{inspect(config_entry)}"
      # )

      # if there was a value of "" for verbose, it would have stayed as "" for log in the last migration
      # this is not valid and was causing a crash on startup. it needs to be false, or a valid log level string

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
