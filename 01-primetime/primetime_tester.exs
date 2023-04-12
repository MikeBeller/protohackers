Mix.install([{:jason, "~> 1.0"}])

ExUnit.start()

defmodule Primetime.PrimetimeTest do
  use ExUnit.Case, async: false

  defp connect(port) do
    {:ok, sock} = :gen_tcp.connect('localhost', port,
      [:binary, active: false, packet: :line, reuseaddr: true])
    sock
  end

  @port 9999

  test "primetime_7" do
    sock = connect(@port)
    msg = Jason.encode!(%{"method" => "isPrime", "number" => 7}) <> "\n"
    assert :ok = :gen_tcp.send(sock, msg)
    assert {:ok, resp} = :gen_tcp.recv(sock, 0, 3000)
    assert Jason.decode!(resp) == %{"method" => "isPrime", "prime" => true}
    :ok = :gen_tcp.close(sock)
  end

  test "primetime_81" do
    sock = connect(@port)
    msg = Jason.encode!(%{"method" => "isPrime", "number" => 81}) <> "\n"
    assert :ok = :gen_tcp.send(sock, msg)
    assert {:ok, resp} = :gen_tcp.recv(sock, 0, 3000)
    assert Jason.decode!(resp) == %{"method" => "isPrime", "prime" => false}
    :ok = :gen_tcp.close(sock)
  end

  # set qs to a list of 5 numbers some of which are prime and some of which are not
  @qs [7, 81, 13, 14, 15]
  # set as to true or false depending on whether the corresponding number in qs is prime
  @as [true, false, true, false, false]

  test "supports 5 simultaneous connections" do
    socks = Enum.map(1..5, fn _ -> connect(@port) end)
    Enum.each(Enum.zip(socks, @qs), fn {sock, q} ->
      assert :ok = :gen_tcp.send(sock, Jason.encode!(%{"method" => "isPrime", "number" => q}) <> "\n")
    end)

    Enum.zip(socks, @as)
    |> Enum.reverse()
    |> Enum.each(fn {sock, a} ->
      assert {:ok, resp} = :gen_tcp.recv(sock, 0, 3000)
      assert Jason.decode!(resp) == %{"method" => "isPrime", "prime" => a}
    end)

    Enum.each(socks, fn sock ->
      :ok = :gen_tcp.close(sock)
    end)
  end


  test "primetime_multiple" do
    sock = connect(@port)
    msg = [7, 81, 13]
    |> Enum.map(fn q -> Jason.encode!(%{"method" => "isPrime", "number" => q}) <> "\n" end)
    |> Enum.join()
    IO.inspect(msg)
    assert :ok = :gen_tcp.send(sock, msg)
    for a <- [true, false, true] do
      assert {:ok, resp} = :gen_tcp.recv(sock, 0, 3000)
      assert Jason.decode!(resp) == %{"method" => "isPrime", "prime" => a}
    end
    :ok = :gen_tcp.close(sock)
  end
end
