defmodule ChatTest.ServerTest do
  use ExUnit.Case
  @port 9999

  defp connect(port) do
    {:ok, sock} = :gen_tcp.connect('localhost', port,
      [:binary, active: false, packet: :line, reuseaddr: true])
    sock
  end

  test "chat_1" do
    {:ok, server_sock} = Chat.Server.init(@port)
    sock = connect(@port)
    assert {:ok, "name?\n"} = :gen_tcp.recv(sock, 0, 3000)
    assert :ok = :gen_tcp.send(sock, "bob\n")
    assert {:ok, "* present: \n"} = :gen_tcp.recv(sock, 0, 3000)
    :ok = :gen_tcp.close(sock)
    :ok = :gen_tcp.close(server_sock)
  end
end
