defmodule Mix.Tasks.Migrator.Import.Votes do
  use Mix.Task
  import Mix.Pleroma
  import Mix.Migrator

  @shortdoc "Import poll votes."
  def run(_) do
    start_pleroma()

    File.stream!("migrator/votes.txt")
    |> Enum.each(&handle_line/1)
  end

  defp handle_line(line) do
    params =
      Jason.decode!(line)
      |> keys_to_atoms
      |> loop_fields([:inserted_at, :updated_at], &parse_timestamp/1)

    shell_info("Importing poll vote...")
    try_create_activity(params)
  end
end
