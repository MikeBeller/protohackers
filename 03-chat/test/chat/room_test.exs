defmodule Chat.RoomTest do
  use ExUnit.Case, async: true
  doctest Chat.Room

  setup do
    _pid = start_supervised!({Chat.Room, :ok})
    %{}
  end

  test "join ok" do
    assert Chat.Room.join("mike", self()) == :ok
  end

  test "no double join" do
    assert Chat.Room.join("mike", self()) == :ok
    assert Chat.Room.join("mike", self()) == {:error, :already_joined}
  end
end
