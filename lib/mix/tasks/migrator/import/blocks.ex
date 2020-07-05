defmodule Mix.Tasks.Migrator.Import.Blocks do
  use Mix.Task
  import Mix.Pleroma
  import Mix.Migrator
  alias Pleroma.User
  alias Pleroma.UserRelationship

  @shortdoc "Import blocks."
  def run(_) do
    start_pleroma()

    File.stream!("migrator/blocks.txt")
    |> Enum.each(&handle_line/1)
  end

  defp handle_line(line) do
    params =
      Jason.decode!(line)
      |> keys_to_atoms
      |> loop_fields([:inserted_at, :updated_at], &parse_timestamp/1)

    try_create_activity(params)
    try_create_block(params)
  end

  defp try_create_block(%{data: %{"actor" => actor, "object" => object}} = _params) do
    try do
      source = User.get_by_ap_id(actor)
      target = User.get_by_ap_id(object)
      UserRelationship.create_block(source, target)
      shell_info("Block created")
    rescue
      MatchError -> shell_info("Could not create block")
      FunctionClauseError -> shell_info("Could not create block")
    end
  end
end
