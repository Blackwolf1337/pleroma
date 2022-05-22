defmodule Mix.Tasks.Migrator.Import.Likes do
  use Mix.Task
  import Mix.Pleroma
  import Mix.Migrator

  @shortdoc "Import likes."
  def run(_) do
    start_pleroma()

    File.stream!("migrator/likes.txt")
    |> Enum.each(&handle_line/1)
  end

  defp handle_line(line) do
    params =
      Jason.decode!(line)
      |> keys_to_atoms
      |> loop_fields([:inserted_at, :updated_at], &parse_timestamp/1)

    shell_info("Importing like...")
    try_create_activity(params)
  end
end
