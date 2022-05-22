defmodule Mix.Tasks.Migrator.Import.Filters do
  use Mix.Task
  import Mix.Pleroma
  import Mix.Migrator
  alias Pleroma.User
  alias Pleroma.Filter
  alias Pleroma.Repo

  @shortdoc "Import filters."
  def run(_) do
    start_pleroma()

    File.stream!("migrator/filters.txt")
    |> Enum.each(&handle_line/1)
  end

  defp handle_line(line) do
    params =
      Jason.decode!(line)
      |> keys_to_atoms
      |> loop_fields([:inserted_at, :updated_at], &parse_timestamp/1)
      |> fix_user_id

    try_create_filter(params)
  end

  defp fix_user_id(params) do
    creator = User.get_by_ap_id(params[:user_ap_id])

    Map.put(params, :user_id, creator.id)
    |> Map.delete(:user_ap_id)
  end

  defp try_create_filter(params) do
    changeset = struct(Filter, params)

    try do
      {:ok, _filter} = Repo.insert(changeset)
      shell_info("Filter created")
    rescue
      Ecto.ConstraintError -> shell_info("Filter already exists, skipping")
      MatchError -> shell_info("Could not create filter")
      FunctionClauseError -> shell_info("Could not create filter")
    end
  end
end
