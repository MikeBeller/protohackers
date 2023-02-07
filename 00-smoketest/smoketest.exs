defmodule Smoke do
  def listen(port) do
    {:ok, sock} = :gen_tcp.listen(port, [:binary, packet: :raw, active: false, reuseaddr: true])
    IO.puts "Accepting connections on port #{port}"
    loop_acceptor(sock)
  end

  defp loop_acceptor(sock) do
    {:ok, client} = :gen_tcp.accept(sock)
    Task.start(fn -> serve_echo(client) end)
    loop_acceptor(sock)
  end

  defp serve_echo(sock) do
    IO.puts "new client #{inspect sock}"
    case :gen_tcp.recv(sock, 0) do
      {:ok, data} ->
        :gen_tcp.send(sock, data)
        serve_echo(sock)
      {:error, :closed} ->
          :gen_tcp.close(sock)
    end
  end
end

##### test code

if System.argv() == ["--serve"] do
  Smoke.listen(9999)
  System.no_halt(true)
else
  ExUnit.start()
end

defmodule Smoke.SmokeTest do
  use ExUnit.Case, async: true

  test "smoke" do
    {:ok, pid} = Task.start_link(fn -> Smoke.listen(9999) end)
    {:ok, sock} = :gen_tcp.connect('localhost', 9999, [:binary, packet: :raw, active: false])
    assert :ok = :gen_tcp.send(sock, "hello")
    assert {:ok, "hello"} = :gen_tcp.recv(sock, 0)
    assert :ok = :gen_tcp.send(sock, "world")
    :ok = :gen_tcp.shutdown(sock, :write)
    assert {:ok, "world"} = :gen_tcp.recv(sock, 0)
    :ok = :gen_tcp.close(sock)
    Process.exit(pid, :kill)
  end
end
