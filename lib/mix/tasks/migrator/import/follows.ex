defmodule Mix.Tasks.Migrator.Import.Follows do
  use Mix.Task
  import Mix.Pleroma
  import Mix.Migrator
  alias Pleroma.User
  alias Pleroma.FollowingRelationship

  @shortdoc "Import follows."
  def run(_) do
    start_pleroma()

    File.stream!("migrator/follows.txt")
    |> Enum.each(&handle_line/1)
  end

  defp handle_line(line) do
    params =
      Jason.decode!(line)
      |> keys_to_atoms
      |> loop_fields([:inserted_at, :updated_at], &parse_timestamp/1)

    shell_info("Importing follow...")
    try_create_activity(params)
    create_follow(params)
  end

  defp create_follow(%{data: %{"actor" => actor, "object" => object}} = _params) do
    try do
      follower = User.get_by_ap_id(actor)
      following = User.get_by_ap_id(object)
      FollowingRelationship.follow(follower, following)
      shell_info("Follow relationship created")
    rescue
      MatchError -> shell_info("Could not create follow")
      FunctionClauseError -> shell_info("Could not create follow")
    end
  end
end
