defmodule Mix.Tasks.Migrator.Rebuild do
  use Mix.Task
  alias Pleroma.Object
  alias Pleroma.User
  alias Pleroma.Web.ActivityPub.ActivityPub
  alias Pleroma.Web.ActivityPub.Transmogrifier

  require Logger
  import Ecto.Query
  import Mix.Pleroma

  @shortdoc "Rebuild remote data."

  def run(["users"]) do
    start_pleroma()

    User
    |> where([u], u.local == false)
    |> where([u], is_nil(u.last_refreshed_at))
    |> Pleroma.RepoStreamer.chunk_stream(500)
    |> Stream.each(fn users ->
      users
      |> Enum.each(fn user ->
        try do
          ActivityPub.make_user_from_ap_id(user.ap_id)
          shell_info("Updating @#{user.nickname}")
        rescue
          _ ->
            shell_info("Couldn't update user. Skipping.")
        end
      end)
    end)
    |> Stream.run()
  end

  def run(["activities"]) do
    start_pleroma()

    Object
    |> where([o], fragment("?->'pleroma_internal'->>'migrator'='true'", o.data))
    |> Pleroma.RepoStreamer.chunk_stream(500)
    |> Stream.each(fn objects ->
      objects
      |> Enum.each(fn object ->
        shell_info("Transmogrifying #{object.data["id"]}")
        # This doesn't write anything back to the database, it just
        # fetches anything that's missing.
        try do
          Transmogrifier.fix_object(object.data)
        rescue
          _ ->
            shell_info("Couldn't transmogrify. Skipping.")
        end
      end)
    end)
    |> Stream.run()
  end
end
