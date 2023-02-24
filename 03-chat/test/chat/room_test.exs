defmodule ChatTest.RoomTest do
  use ExUnit.Case, async: true
  doctest Chat.Room

  setup do
    _pid = start_supervised!({Chat.Room, :ok})
    %{}
  end

  test "join ok" do
    assert Chat.Room.join(self(), "mike") == :ok
  end

  test "sends messages" do
    t1 = Task.async(fn ->
      assert Chat.Room.join(self(), "mike") == :ok
      assert_receive "* present: "
      assert_receive "* joe has joined the room"
      assert_receive "[joe] hello"
      :ok
    end)
    Process.sleep(10)
    t2 = Task.async(fn ->
      assert Chat.Room.join(self(), "joe") == :ok
      assert_receive "* present: mike"
      Chat.Room.broadcast(self(), "hello")
    end)
    :ok = Task.await(t1)
    IO.inspect Task.await(t2)
    #assert_receive "hello"
  end

  test "leaves" do
    t1 = Task.async(fn ->
      assert Chat.Room.join(self(), "mike") == :ok
      assert_receive "* present: "
      assert_receive "* joe has joined the room"
      assert_receive "[joe] hello"
      assert_receive "* joe has left the room"
      :ok
    end)
    Process.sleep(10)
    t2 = Task.async(fn ->
      assert Chat.Room.join(self(), "joe") == :ok
      assert_receive "* present: mike"
      Chat.Room.broadcast(self(), "hello")
      :ok
    end)
    :ok = Task.await(t2)
    :ok = Task.await(t1)
  end
end
