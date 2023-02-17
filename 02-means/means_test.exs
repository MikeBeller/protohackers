Mix.install([{:porcelain, "~> 2.0"}])

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

  setup_all do
    pid = Porcelain.spawn("elixir", ["means.exs"])
    IO.puts "Started #{inspect(pid)}"
    Process.sleep(1000)
    on_exit(fn ->
      IO.puts "Stopping #{inspect(pid)}"
      Porcelain.Process.stop(pid)
      Porcelain.Process.await(pid)
      IO.puts("Stopped #{inspect(pid)}")
    end)
    {:ok, pid: pid}
  end

  test "handles one item" do
    sock = connect(@port)
    assert :ok = :gen_tcp.send(sock, insert_msg(@test_now, 100))
    assert :ok = :gen_tcp.send(sock, query_msg(@test_now-10, @test_now+10))
    assert {:ok, resp} = :gen_tcp.recv(sock, 4, 3000)
    assert <<100::size(32)>> = resp
    :ok = :gen_tcp.close(sock)
  end

  test "handles no items" do
    sock = connect(@port)
    assert :ok = :gen_tcp.send(sock, query_msg(@test_now-10, @test_now+10))
    assert {:ok, resp} = :gen_tcp.recv(sock, 4, 3000)
    assert <<0::size(32)>> = resp
    :ok = :gen_tcp.close(sock)
  end

  test "handles multiple items" do
    sock = connect(@port)
    assert :ok = :gen_tcp.send(sock, insert_msg(@test_now, 100))
    assert :ok = :gen_tcp.send(sock, insert_msg(@test_now+10, 200))
    assert :ok = :gen_tcp.send(sock, insert_msg(@test_now+20, 300))
    assert :ok = :gen_tcp.send(sock, query_msg(@test_now, @test_now+30))
    assert {:ok, <<200::size(32)>>} = :gen_tcp.recv(sock, 4, 3000)
    assert :ok = :gen_tcp.send(sock, insert_msg(@test_now+15, 400))
    assert :ok = :gen_tcp.send(sock, query_msg(@test_now, @test_now+21))
    assert {:ok, <<250::size(32)>>} = :gen_tcp.recv(sock, 4, 3000)
    :ok = :gen_tcp.close(sock)
  end

  test "handles negative price" do
    sock = connect(@port)
    assert :ok = :gen_tcp.send(sock, insert_msg(@test_now, -100))
    assert :ok = :gen_tcp.send(sock, query_msg(@test_now-10, @test_now+10))
    assert {:ok, resp} = :gen_tcp.recv(sock, 4, 3000)
    assert <<-100::signed-integer-size(32)>> = resp
    :ok = :gen_tcp.close(sock)
  end


end
