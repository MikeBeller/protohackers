defmodule ChatTest.ServerTest do
  use ExUnit.Case, async: false
  @test_port 7777

  setup do
    _pid0 = start_supervised!({Task.Supervisor, name: Chat.TaskSupervisor})
    _pid1 = start_supervised!({Chat.Room, :ok})
    {:ok, server_sock} = :gen_tcp.listen(@test_port, [:binary, packet: :line, active: false, reuseaddr: true])
    _pid2 = start_supervised!({Task, fn -> Chat.Server.loop_acceptor(server_sock) end})
    %{}
  end

  defp connect(port) do
    {:ok, sock} = :gen_tcp.connect('localhost', port,
      [:binary, active: false, packet: :line, send_timeout: 1000])
    sock
  end

  defp send_sock(sock, msg) do
    :gen_tcp.send(sock, msg <> "\n")
  end

  defp recv_sock(sock) do
    {:ok, msg} = :gen_tcp.recv(sock, 0, 3000)
    {:ok, String.trim_trailing(msg, "\n")}
  end

  test "chat_1" do
    sock = connect(@test_port)
    assert {:ok, "name?"} = recv_sock(sock)
    assert :ok = :gen_tcp.send(sock, "bob\n")
    assert {:ok, "* present: "} = recv_sock(sock)
    :ok = :gen_tcp.close(sock)
  end

  defp login(port, name) do
    sock = connect(port)
    assert {:ok, "name?"} = recv_sock(sock)
    assert :ok = send_sock(sock, name)
    assert {:ok, msg} = recv_sock(sock)
    assert <<"* present: " <> rest>> = msg
    present = String.split(rest, ", ")
    |> Enum.filter(fn x -> x != "" end)
    {sock, present}
  end

  test "chat_2" do
    {_sock1, []}  = login(@test_port, "alice")
    {_sock2, ["alice"]} = login(@test_port, "bob")

  end

end
