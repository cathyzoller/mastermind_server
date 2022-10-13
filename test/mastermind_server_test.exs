defmodule MastermindServerTest do
  use ExUnit.Case
  doctest MastermindServer

  test "greets the world" do
    assert MastermindServer.hello() == :world
  end
end
