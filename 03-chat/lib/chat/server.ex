defmodule Chat.Server do
  @port 9999

  def init(port \\ @port) do
    {:ok, server_sock} = :gen_tcp.listen(port, [:binary, packet: :line, active: true, reuseaddr: true])
    IO.puts "Accepting connections on port #{port}"
    _task = Task.start_link(fn -> loop_acceptor(server_sock) end)
    {:ok, server_sock}
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
        IO.inspect(err)
    end
  end
end
