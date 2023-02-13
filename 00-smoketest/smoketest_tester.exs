ExUnit.start()

defmodule Smoke.SmokeTest do
  use ExUnit.Case

  defp connect(port) do
    {:ok, sock} = :gen_tcp.connect('localhost', port,
      [:binary, active: false, packet: :raw, reuseaddr: true])
    sock
  end

  @port 9999

  test "smoke" do
    sock = connect(@port)
    assert :ok = :gen_tcp.send(sock, "hello")
    assert {:ok, "hello"} = :gen_tcp.recv(sock, 0, 3000)
    assert :ok = :gen_tcp.send(sock, "world")
    :ok = :gen_tcp.shutdown(sock, :write)
    assert {:ok, "world"} = :gen_tcp.recv(sock, 0, 3000)
    :ok = :gen_tcp.close(sock)
  end

  test "supports 5 simultaneous connections" do
    socks = Enum.map(1..5, fn _ -> connect(@port) end)
    Enum.each(socks, fn sock ->
      assert :ok = :gen_tcp.send(sock, "hello")
    end)

    socks
    |> Enum.reverse()
    |> Enum.each(fn sock ->
      assert {:ok, "hello"} = :gen_tcp.recv(sock, 0, 3000)
    end)

    Enum.each(socks, fn sock ->
      :ok = :gen_tcp.close(sock)
    end)
  end

end
