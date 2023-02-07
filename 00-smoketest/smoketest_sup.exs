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
    DynamicSupervisor.start_child(Smoke.WorkerSupervisor, {Task, fn -> smoke_worker(client) end})
    loop_acceptor(sock)
  end

  defp smoke_worker(sock) do
    IO.puts "new client #{inspect sock}"
    case :gen_tcp.recv(sock, 0) do
      {:ok, data} ->
        :gen_tcp.send(sock, data)
        smoke_worker(sock)
      {:error, err} ->
        IO.inspect(err)
    end
  end
end

defmodule Smoke.Supervisor do
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  @impl true
  def init(:ok) do
    children = [
      {Task, fn -> Smoke.listen(9999) end},
      {DynamicSupervisor, name: Smoke.WorkerSupervisor, strategy: :one_for_one}
    ]

    opts = [strategy: :one_for_one, name: Smoke.Supervisor]
    Supervisor.init(children, opts)
  end
end

{:ok, _pid} = Smoke.Supervisor.start_link([])
receive do _ -> 1 end
