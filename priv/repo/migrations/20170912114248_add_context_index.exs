defmodule Pleroma.Storage.Repo.Migrations.AddContextIndex do
  use Ecto.Migration
  @disable_ddl_transaction true
  @disable_migration_lock true

  def change do
    create(
      index(:activities, ["(data->>'type')", "(data->>'context')"],
        name: :activities_context_index,
        concurrently: true
      )
    )
  end
end
