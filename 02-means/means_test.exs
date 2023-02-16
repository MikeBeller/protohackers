Mix.install([{:jason, "~> 1.0"}])

ExUnit.start()

defmodule Means.MeansTest do
  use ExUnit.Case

  defp connect(port) do
    {:ok, sock} = :gen_tcp.connect('localhost', port,
      [:binary, active: false, packet: :raw, reuseaddr: true])
    sock
  end

  @port 9999

  @test_now 1676562865

  defp insert_msg(ts, price) do
    <<?I, ts::size(32), price::size(32)>>
  end

  defp query_msg(min_ts, max_ts) do
    <<?Q, min_ts::size(32), max_ts::size(32)>>
  end

  test "handles one item" do
    sock = connect(@port)
    assert :ok = :gen_tcp.send(sock, insert_msg(@test_now, 100))
    assert :ok = :gen_tcp.send(sock, query_msg(@test_now-10, @test_now+10))
    assert {:ok, resp} = :gen_tcp.recv(sock, 4, 3000)
    assert <<100::size(32)>> = resp
    :ok = :gen_tcp.close(sock)
  end
end
