defmodule VoxpubUserTest do
  use ExUnit.Case
  doctest VoxpubUser

  test "greets the world" do
    assert VoxpubUser.hello() == :world
  end
end
