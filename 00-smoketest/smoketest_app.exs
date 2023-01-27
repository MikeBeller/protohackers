defmodule Smoke do
  def listen(port) do
    {:ok, sock} = :gen_tcp.listen(port, [:binary, packet: :raw, active: false, reuseaddr: true])
    IO.puts "Accepting connections on port #{port}"
    loop_acceptor(sock)
    IO.puts "got here"
  end

  defp loop_acceptor(sock) do
    IO.puts "waiting"
    {:ok, client} = IO.inspect(:gen_tcp.accept(sock))
    IO.puts "accepted"
    Task.start(fn -> serve_echo(client) end)
    loop_acceptor(sock)
  end

  defp serve_echo(sock) do
    IO.puts "new client #{inspect sock}"
    case :gen_tcp.recv(sock, 0) do
      {:ok, data} ->
        :gen_tcp.send(sock, data)
        serve_echo(sock)
      {:error, err} ->
        IO.inspect(err)
    end
  end
end

defmodule Smoke.Application do
  use Application
  @impl true
  def start(_type, _args) do

  end
end

{:ok, _pid} = Supervisor.start_link(children, strategy: :one_for_one, name: :port_supervisor)

#Smoke.listen(9999)
System.no_halt(true)
