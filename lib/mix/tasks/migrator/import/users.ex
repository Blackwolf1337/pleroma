defmodule Mix.Tasks.Migrator.Import.Users do
  use Mix.Task
  import Mix.Pleroma
  import Mix.Migrator
  alias Pleroma.User
  alias Pleroma.Repo

  @shortdoc "Import users."
  def run(_) do
    start_pleroma()

    File.stream!("migrator/users.txt")
    |> Enum.each(&handle_line/1)
  end

  defp handle_line(line) do
    bio_limit = Pleroma.Config.get([:instance, :user_bio_length], 5000)
    name_limit = Pleroma.Config.get([:instance, :user_name_length], 100)

    params =
      Jason.decode!(line)
      |> keys_to_atoms
      |> loop_fields(
        [
          :inserted_at,
          :updated_at,
          :last_digest_emailed_at
        ],
        &parse_timestamp/1
      )
      |> loop_fields([:last_refreshed_at], &parse_timestamp_usec/1)
      |> loop_fields([:notification_settings], &keys_to_atoms/1)
      |> loop_fields([:name], &truncate(&1, name_limit))
      |> loop_fields([:bio], &truncate(&1, bio_limit))

    changeset = struct(User, params)

    try do
      {:ok, user} = Repo.insert(changeset)
      User.set_cache(user)
      shell_info("User #{params.nickname} created")
    rescue
      Ecto.ConstraintError ->
        shell_info("User #{params.nickname} already in database, skipping")
    end
  end
end
