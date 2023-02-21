
defmodule Means do
  def compute_mean(state, min_ts, max_ts) do
    prices = state
    |> Map.to_list()
    |> Enum.filter(fn {ts, _} -> ts >= min_ts and ts <= max_ts end)
    |> Enum.map(fn {_, prc} -> prc end)
    case prices do
      [] -> 0
      _ ->
        Enum.sum(prices) / Enum.count(prices) |> trunc() |> IO.inspect()
    end
  end

  def start(port) do
    {:ok, sock} = :gen_tcp.listen(port, [:binary, packet: :raw, active: false, reuseaddr: true])
    IO.puts "Accepting connections on port #{port}"
    _task = Task.start(fn -> loop_acceptor(sock) end)
    IO.read(:stdio, :all)
    :gen_tcp.close(sock)
    System.halt(0)
  end

  defp loop_acceptor(sock) do
    case :gen_tcp.accept(sock) do
      {:ok, client} ->
        Task.start(fn -> serve_means(client) end)
        loop_acceptor(sock)
      {:error, :eagain} ->
        loop_acceptor(sock)
      {:error, err} ->
        IO.inspect(err)
    end
  end

  defp serve_means(sock, state \\ %{}) do
    case :gen_tcp.recv(sock, 9) do
      {:ok, <<?I, ts::size(32), prc::signed-integer-size(32)>>} ->
        serve_means(sock, Map.put(state, ts, prc))
      {:ok, <<?Q, min_ts::signed-integer-size(32), max_ts::signed-integer-size(32)>>} ->
        IO.puts "Querying #{min_ts} - #{max_ts}"
        mean = compute_mean(state, min_ts, max_ts)
        :gen_tcp.send(sock, <<mean::signed-integer-size(32)>>)
        serve_means(sock, state)
      {:ok, _} ->
        :gen_tcp.close(sock)
      {:error, :closed} ->
        :gen_tcp.close(sock)
      {:error, err} ->
        IO.inspect(err)
    end
  end
end

Means.start(9999)
