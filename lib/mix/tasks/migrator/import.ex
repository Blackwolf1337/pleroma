defmodule Mix.Tasks.Migrator.Import do
  use Mix.Task
  alias Mix.Tasks.Migrator

  @shortdoc "Import all dumps."
  def run(_) do
    Migrator.Import.Users.run(nil)
    Migrator.Import.Statuses.run(nil)
    Migrator.Import.Likes.run(nil)
    Migrator.Import.Follows.run(nil)
    Migrator.Import.Votes.run(nil)
    Migrator.Import.Blocks.run(nil)
    Migrator.Import.Mutes.run(nil)
    Migrator.Import.ThreadMutes.run(nil)
    Migrator.Import.Lists.run(nil)
    Migrator.Import.Filters.run(nil)
  end
end
