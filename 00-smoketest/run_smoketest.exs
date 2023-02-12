ExUnit.start()

defmodule Smoke.SmokeTest do
  use ExUnit.Case, async: true

  @port 9999

  setup do
    pid = Port.open({:spawn_executable, "../helpers/runner.sh"},
      args: ["python3", "smoketest.py", to_string(@port)])
    IO.puts "started server"
    on_exit(
      fn -> Port.close(pid) end
    )
  end

  test "smoke" do
    IO.puts "connecting to server"
    {:ok, sock} = :gen_tcp.connect('localhost', @port, [:binary, packet: :raw, active: false])
    assert :ok = :gen_tcp.send(sock, "hello")
    assert {:ok, "hello"} = :gen_tcp.recv(sock, 0)
    assert :ok = :gen_tcp.send(sock, "world")
    :ok = :gen_tcp.shutdown(sock, :write)
    assert {:ok, "world"} = :gen_tcp.recv(sock, 0)
    :ok = :gen_tcp.close(sock)
    IO.puts "OK"
  end
end
