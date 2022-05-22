defmodule Mix.Tasks.Migrator.Import.Lists do
  use Mix.Task
  import Mix.Pleroma
  import Mix.Migrator
  alias Pleroma.User
  alias Pleroma.List
  alias Pleroma.Repo

  @shortdoc "Import lists."
  def run(_) do
    start_pleroma()

    File.stream!("migrator/lists.txt")
    |> Enum.each(&handle_line/1)
  end

  defp handle_line(line) do
    params =
      Jason.decode!(line)
      |> keys_to_atoms
      |> loop_fields([:inserted_at, :updated_at], &parse_timestamp/1)
      |> fix_user_id

    try_create_list(params)
  end

  defp fix_user_id(params) do
    creator = User.get_by_ap_id(params[:user_ap_id])

    Map.put(params, :user_id, creator.id)
    |> Map.delete(:user_ap_id)
  end

  defp try_create_list(params) do
    changeset = struct(List, params)

    try do
      {:ok, _list} = Repo.insert(changeset)
      shell_info("List created")
    rescue
      Ecto.ConstraintError -> shell_info("List already exists, skipping")
      MatchError -> shell_info("Could not create list")
      FunctionClauseError -> shell_info("Could not create list")
    end
  end
end
