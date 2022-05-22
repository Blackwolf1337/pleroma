defmodule Mix.Tasks.Migrator.Import.Statuses do
  use Mix.Task
  import Mix.Pleroma
  import Mix.Migrator

  @shortdoc "Import statuses."
  def run(_) do
    start_pleroma()

    File.stream!("migrator/statuses.txt")
    |> Enum.each(&handle_line/1)
  end

  defp handle_line(line) do
    params =
      Jason.decode!(line)
      |> keys_to_atoms
      |> loop_fields([:inserted_at, :updated_at], &parse_timestamp/1)

    shell_info("Importing status #{params.id}...")
    try_create_activity(params)
  end
end
