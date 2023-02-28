defmodule ChatTest.RoomTest do
  use ExUnit.Case, async: false
  doctest Chat.Room

  setup do
    _pid = start_supervised!({Chat.Room, :ok})
    %{}
  end

  test "join ok" do
      assert {:ok, "* present: "} = Chat.Room.join(self(), "mike")
  end

  test "sends messages" do
    t1 = Task.async(fn ->
      assert {:ok, "* present: "} = Chat.Room.join(self(), "mike")
      assert_receive {:chat, "* joe has joined the room"}
      assert_receive {:chat, "[joe] hello"}
      :ok
    end)
    Process.sleep(10)
    t2 = Task.async(fn ->
      assert {:ok, "* present: mike"} = Chat.Room.join(self(), "joe")
      Chat.Room.broadcast(self(), "hello")
    end)
    :ok = Task.await(t1)
    IO.inspect Task.await(t2)
    #assert_receive "hello"
  end

  test "leaves" do
    t1 = Task.async(fn ->
      assert {:ok, "* present: "} = Chat.Room.join(self(), "mike")
      assert_receive {:chat, "* joe has joined the room"}
      assert_receive {:chat, "[joe] hello"}
      assert_receive {:chat, "* joe has left the room"}
      :ok
    end)
    Process.sleep(10)
    t2 = Task.async(fn ->
      assert {:ok, "* present: mike"} = Chat.Room.join(self(), "joe")
      Chat.Room.broadcast(self(), "hello")
      :ok
    end)
    :ok = Task.await(t2)
    :ok = Task.await(t1)
  end
end
