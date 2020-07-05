defmodule Mix.Tasks.Migrator.Import.Mutes do
  use Mix.Task
  import Mix.Pleroma
  import Mix.Migrator
  alias Pleroma.User
  alias Pleroma.UserRelationship

  @shortdoc "Import mutes."
  def run(_) do
    start_pleroma()

    File.stream!("migrator/mutes.txt")
    |> Enum.each(&handle_line/1)
  end

  defp handle_line(line) do
    params =
      Jason.decode!(line)
      |> keys_to_atoms
      |> loop_fields([:inserted_at, :updated_at], &parse_timestamp/1)

    try_create_mute(params)
  end

  defp try_create_mute(%{source_ap_id: source_ap_id, target_ap_id: target_ap_id} = _params) do
    try do
      source = User.get_by_ap_id(source_ap_id)
      target = User.get_by_ap_id(target_ap_id)
      UserRelationship.create_mute(source, target)
      shell_info("Mute created")
    rescue
      MatchError -> shell_info("Could not create mute")
      FunctionClauseError -> shell_info("Could not create mute")
    end
  end
end
