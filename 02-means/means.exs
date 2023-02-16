
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

  def listen(port) do
    {:ok, sock} = :gen_tcp.listen(port, [:binary, packet: :raw, active: false, reuseaddr: true])
    IO.puts "Accepting connections on port #{port}"
    loop_acceptor(sock)
  end

  defp loop_acceptor(sock) do
    {:ok, client} = :gen_tcp.accept(sock)
    Task.start(fn -> serve_means(client) end)
    loop_acceptor(sock)
  end

  defp serve_means(sock, state \\ %{}) do
    case :gen_tcp.recv(sock, 9) do
      {:ok, <<?I, ts::size(32), prc::size(32)>>} ->
        serve_means(sock, Map.put(state, ts, prc))
      {:ok, <<?Q, min_ts::size(32), max_ts::size(32)>>} ->
        IO.puts "Querying #{min_ts} - #{max_ts}"
        mean = compute_mean(state, min_ts, max_ts)
        :gen_tcp.send(sock, <<mean::size(32)>>)
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

Means.listen(9999)
Pocess.sleep(:infinity)
