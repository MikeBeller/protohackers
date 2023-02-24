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

  test "sends messages" do
    t1 = Task.start(fn ->
      assert Chat.Room.join("mike", self()) == :ok
      assert_receive "* present: mike"
      assert_receive "* joe has joined the room"
    end)
    Process.sleep(1000)
    t2 = Task.start(fn ->
      assert Chat.Room.join("joe", self()) == :ok
      assert_receive "* present: joe, mike"
    end)
    #Task.await(t1)
    #Task.await(t2)
    #assert_receive "hello"
  end
end
