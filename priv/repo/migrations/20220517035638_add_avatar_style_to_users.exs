defmodule Pleroma.Repo.Migrations.AddAvatarStyleToUsers do
  use Ecto.Migration

  def up do
    alter table(:users) do
      add_if_not_exists(:avatar_style, :string)
    end
  end

  def down do
    alter table(:users) do
      remove_if_exists(:avatar_style, :string)
    end
  end
end
