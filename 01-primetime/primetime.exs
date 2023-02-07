Mix.install({:jason, "~> 1.0"})

defmodule Smoke do
  def listen(port) do
    {:ok, sock} = :gen_tcp.listen(port, [:binary, packet: :line, active: false, reuseaddr: true])
    IO.puts "Accepting connections on port #{port}"
    loop_acceptor(sock)
  end

  defp loop_acceptor(sock) do
    {:ok, client} = :gen_tcp.accept(sock)
    Task.start(fn -> serve_prime(client) end)
    loop_acceptor(sock)
  end

  defp error_json() do
    Jason.encode!(%{"error" => "invalid"}) <> "\n"
  end

  # need prime algo
  defp prime(num) do
    false
  end

  defp primetime(data) do
    case Jason.decode(data) do
      {:ok, %{"method" => "isPrime", "number" => num when is_integer(num)}} ->
        Jason.encode!(%{"method" => "isPrime", "prime" => prime(num)}) <> "\n"
      {:ok, %{"method" => "isPrime", "number" => num when is_float(num)}} ->
        Jason.encode!(%{"method" => "isPrime", "prime" => false}) <> "\n"
      _ -> error_json()
    end
  end

  defp serve_echo(sock) do
    IO.puts "new client #{inspect sock}"
    case :gen_tcp.recv(sock, 0) do
      {:ok, data} ->
        resp = primetime(data)
        :gen_tcp.send(sock, resp)
        serve_echo(sock)
      {:error, err} ->
        IO.inspect(err)
    end
  end
end

Smoke.listen(9999)
Pocess.sleep(:infinity)
