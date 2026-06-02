defmodule Bonfire.Data.Identity.CharacterTest do
  use ExUnit.Case, async: true
  doctest Bonfire.Data.Identity.Character, import: true

  alias Bonfire.Data.Identity.Character

  describe "uniform/1" do
    test "a username ending in 7 does not collide with the same name ending in l or 1" do
      refute Character.uniform("bob7") == Character.uniform("bobl")
      refute Character.uniform("bob7") == Character.uniform("bob1")
    end

    test "7 is left intact (not folded to l)" do
      assert Character.uniform("bob7") == "bob7"
    end

    test "other confusable folds still apply" do
      assert Character.uniform("b0b1") == "bobl"
    end
  end

  describe "hash/1" do
    test "a username ending in 7 hashes differently from the same name ending in l" do
      refute Character.hash("bob7") == Character.hash("bobl")
    end
  end
end
