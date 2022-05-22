defmodule Mix.Migrator do
  import Mix.Pleroma
  alias Pleroma.Activity
  alias Pleroma.Object
  alias Pleroma.Repo
  alias Pleroma.Web.ActivityPub.Transmogrifier

  @doc "Common functions to be reused in migrator tasks"
  def keys_to_atoms(map) do
    Map.new(map, fn {k, v} -> {String.to_atom(k), v} end)
  end

  def loop_fields(map, fields, fun) do
    Enum.reduce(fields, map, fn key, acc ->
      if Map.has_key?(acc, key) do
        Map.put(acc, key, fun.(acc[key]))
      else
        acc
      end
    end)
  end

  def parse_timestamp_usec(timestamp) do
    case NaiveDateTime.from_iso8601(timestamp) do
      {:ok, dt} -> dt
      {:error, reason} -> IO.puts("Error: #{reason}")
    end
  end

  def parse_timestamp(timestamp) do
    parse_timestamp_usec(timestamp)
    |> NaiveDateTime.truncate(:second)
  end

  def parse_id_list(id_list) do
    Enum.map(id_list, fn id ->
      id
      |> FlakeId.from_integer()
      |> FlakeId.to_string()
    end)
  end

  def truncate(str, max_length) do
    String.slice(str, 0, max_length)
  end

  def try_create_activity(params) do
    activity_params =
      params
      |> Map.delete(:object_data)

    try do
      {:ok, _activity} = Repo.insert(struct(Activity, activity_params))
      shell_info("Activity created")

      if params[:object_data] do
        try_create_object(params)
      end
    rescue
      Ecto.ConstraintError ->
        shell_info("Activity already in database, skipping")
    end
  end

  defp try_create_object(params) do
    object_data =
      params[:object_data]
      # |> Transmogrifier.strip_internal_fields # We need internal fields for `likes` and `like_count`, etc
      # |> Transmogrifier.fix_actor # Makes network requests
      |> Transmogrifier.fix_url()
      |> Transmogrifier.fix_attachments()
      |> Transmogrifier.fix_context()
      # |> Transmogrifier.fix_in_reply_to # Makes network requests
      |> Transmogrifier.fix_emoji()
      |> Transmogrifier.fix_tag()
      |> Transmogrifier.fix_content_map()
      # |> Transmogrifier.fix_addressing # Makes network requests
      |> Transmogrifier.fix_summary()

    # |> Transmogrifier.fix_type

    object_params = %{
      data: object_data,
      inserted_at: params[:inserted_at],
      updated_at: params[:updated_at]
    }

    try do
      {:ok, _object} = Repo.insert(struct(Object, object_params))
      shell_info("Object created")
    rescue
      Ecto.ConstraintError ->
        shell_info("Object already in database, skipping")
    end
  end
end
