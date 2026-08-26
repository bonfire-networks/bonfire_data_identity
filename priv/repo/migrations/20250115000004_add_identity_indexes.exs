defmodule Bonfire.Data.Identity.Repo.Migrations.AddIdentityIndexes do
  @moduledoc false
use Ecto.Migration 
  use Needle.Migration.Indexable

  def up do
    Bonfire.Data.Identity.Character.Migration.add_character_feed_indexes()
  end

  def down, do: nil
end
