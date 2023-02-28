defmodule Chat.Server do
  @port 9999

  def start(port \\ @port) do
    {:ok, server_sock} = :gen_tcp.listen(port, [:binary, packet: :line, active: false, reuseaddr: true])
    IO.puts "Accepting connections on port #{port}"
    loop_acceptor(server_sock)
  end

  def loop_acceptor(server_sock) do
    case :gen_tcp.accept(server_sock) do
      {:ok, client_sock} ->
        {:ok, pid} = Task.Supervisor.start_child(Chat.TaskSupervisor,
          fn -> Chat.Channel.serve_client(client_sock) end)
        :ok = :gen_tcp.controlling_process(client_sock, pid)
        loop_acceptor(server_sock)
      {:error, :eagain} ->
        loop_acceptor(server_sock)
      {:error, err} ->
        IO.puts("Acceptor quit with error: #{inspect err}")
        err
    end
  end
end
