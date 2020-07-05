defmodule Mix.Tasks.Migrator.Import.ThreadMutes do
  use Mix.Task
  import Mix.Pleroma
  import Mix.Migrator
  alias Pleroma.User
  alias Pleroma.ThreadMute

  @shortdoc "Import thread mutes."
  def run(_) do
    start_pleroma()

    File.stream!("migrator/thread_mutes.txt")
    |> Enum.each(&handle_line/1)
  end

  defp handle_line(line) do
    params =
      Jason.decode!(line)
      |> keys_to_atoms

    try_create_thread_mute(params)
  end

  defp try_create_thread_mute(%{ap_id: ap_id, context: context} = _params) do
    try do
      %User{id: user_id} = User.get_by_ap_id(ap_id)
      ThreadMute.add_mute(user_id, context)
      shell_info("Thread mute created")
    rescue
      MatchError -> shell_info("Could not create thread mute")
      FunctionClauseError -> shell_info("Could not create thread mute")
    end
  end
end
