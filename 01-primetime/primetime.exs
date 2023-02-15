Mix.install([{:jason, "~> 1.0"}])

defmodule PrimeTime do
  def is_prime(n) do
    MillerRabin.miller_rabin?(n, 10)
  end

  def listen(port) do
    {:ok, sock} = :gen_tcp.listen(port, [:binary, packet: :line, active: false, reuseaddr: true, ip: {127,0,0,1}])
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

  defp primetime(data) do
    IO.puts "got data #{inspect data}"
    case Jason.decode(data) do
      {:ok, %{"method" => "isPrime", "number" => num }} when is_integer(num) ->
        Jason.encode!(%{"method" => "isPrime", "prime" => is_prime(num)}) <> "\n"
      {:ok, %{"method" => "isPrime", "number" => num}}  when is_float(num) ->
        Jason.encode!(%{"method" => "isPrime", "prime" => false}) <> "\n"
      _ -> error_json()
    end
  end

  defp serve_prime(sock) do
    IO.puts "new client #{inspect sock}"
    case :gen_tcp.recv(sock, 0) do
      {:ok, data} ->
        resp = primetime(data)
        :gen_tcp.send(sock, resp)
        serve_prime(sock)
      {:error, err} ->
        IO.inspect(err)
    end
  end
end

defmodule MillerRabin do
  def modular_exp( x, y, mod ) do
     with [ _ | bits ] = Integer.digits( y, 2 ) do
          Enum.reduce bits, x, fn( bit, acc ) -> acc * acc |> ( &( if bit == 1, do: &1 * x, else: &1 ) ).() |> rem( mod ) end
     end
  end

  def miller_rabin( d, s ) when rem( d, 2 ) == 0, do: { s, d }
  def miller_rabin( d, s ), do: miller_rabin( div( d, 2 ), s + 1 )

  def miller_rabin?( n, g ) do
       { s, d } = miller_rabin( n - 1, 0 )
       miller_rabin( n, g, s, d )
  end

  def miller_rabin( n, 0, _, _ ), do: true
  def miller_rabin( n, g, s, d ) do
    a = 1 + :rand.uniform( n - 3 )
    x = modular_exp( a, d, n )
    if x == 1 or x == n - 1 do
      miller_rabin( n, g - 1, s, d )
    else
      if miller_rabin( n, x, s - 1) == True, do: miller_rabin( n, g - 1, s, d ), else: false
    end
  end

  def miller_rabin( n, x, r ) when r <= 0, do: false
  def miller_rabin( n, x, r ) do
    x = modular_exp( x, 2, n )
    unless x == 1 do
      unless x == n - 1, do: miller_rabin( n, x, r - 1 ), else: true
    else
      False
    end
  end
end

PrimeTime.listen(9999)
Pocess.sleep(:infinity)
