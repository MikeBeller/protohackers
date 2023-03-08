ExUnit.start()

defmodule DatabaseTest do
  use ExUnit.Case, async: false

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
    {:ok, {_, _, "name=Mike"}} = :gen_udp.recv(socket, 0)
  end

  test "set and then change the same key" do
    {:ok, socket} = :gen_udp.open(0, [:binary, active: false])
    :gen_udp.send(socket, {127, 0, 0, 1}, 9999, "name=Mike")
    :gen_udp.send(socket, {127, 0, 0, 1}, 9999, "name=Bob")
    :gen_udp.send(socket, {127, 0, 0, 1}, 9999, "name")
    {:ok, {_, _, "name=Bob"}} = :gen_udp.recv(socket, 0)
  end

  test "set with two = signs" do
    {:ok, socket} = :gen_udp.open(0, [:binary, active: false])
    :gen_udp.send(socket, {127, 0, 0, 1}, 9999, "foo=bar=baz")
    :gen_udp.send(socket, {127, 0, 0, 1}, 9999, "foo")
    {:ok, {_, _, "foo=bar=baz"}} = :gen_udp.recv(socket, 0)
    :gen_udp.send(socket, {127, 0, 0, 1}, 9999, "foo===")
    :gen_udp.send(socket, {127, 0, 0, 1}, 9999, "foo")
    {:ok, {_, _, "foo==="}} = :gen_udp.recv(socket, 0)
  end

  test "key is empty string" do
    {:ok, socket} = :gen_udp.open(0, [:binary, active: false])
    :gen_udp.send(socket, {127, 0, 0, 1}, 9999, "=bar")
    :gen_udp.send(socket, {127, 0, 0, 1}, 9999, "")
    {:ok, {_, _, "=bar"}} = :gen_udp.recv(socket, 0)
  end

  test "double equals" do
    {:ok, socket} = :gen_udp.open(0, [:binary, active: false])
    :gen_udp.send(socket, {127, 0, 0, 1}, 9999, "foo===")
    :gen_udp.send(socket, {127, 0, 0, 1}, 9999, "foo")
    {:ok, {_, _, "foo==="}} = :gen_udp.recv(socket, 0)
  end
end
