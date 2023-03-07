ExUnit.start()

defmodule DatabaseTest do
  use ExUnit.Case, async: true

  test "version" do
    {:ok, socket} = :gen_udp.open(0, [:binary, active: false])
    :gen_udp.send(socket, {127, 0, 0, 1}, 9999, "version")
    {:ok, {_, _, msg}} = :gen_udp.recv(socket, 0)
    IO.puts msg
  end

  test "set and get" do
    {:ok, socket} = :gen_udp.open(0, [:binary, active: false])
    :gen_udp.send(socket, {127, 0, 0, 1}, 9999, "name=Mike")
    :gen_udp.send(socket, {127, 0, 0, 1}, 9999, "name")
    {:ok, {_, _, "Mike"}} = :gen_udp.recv(socket, 0)
  end

  test "set and then change the same key" do
    {:ok, socket} = :gen_udp.open(0, [:binary, active: false])
    :gen_udp.send(socket, {127, 0, 0, 1}, 9999, "name=Mike")
    :gen_udp.send(socket, {127, 0, 0, 1}, 9999, "name=Bob")
    :gen_udp.send(socket, {127, 0, 0, 1}, 9999, "name")
    {:ok, {_, _, "Bob"}} = :gen_udp.recv(socket, 0)
  end
end
