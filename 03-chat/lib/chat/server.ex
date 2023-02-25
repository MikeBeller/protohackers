defmodule Chat.Server do

  def init(port \\ 9999) do
    {:ok, server_sock} = :gen_tcp.listen(port, [:binary, packet: :line, active: false])
    IO.puts "Accepting connections on port #{port}"
    #_task = Task.start_link(fn -> loop_acceptor(server_sock) end)  # acceptor crash will crash client?
    spawn(fn -> loop_acceptor(server_sock) end)
    {:ok, server_sock}
  end

  def loop_acceptor(server_sock) do
    case :gen_tcp.accept(server_sock) do
      {:ok, client_sock} ->
        Task.Supervisor.start_child(Chat.TaskSupervisor,
          fn -> Chat.Channel.serve_client(client_sock) end)
        loop_acceptor(server_sock)
      {:error, :eagain} ->
        loop_acceptor(server_sock)
      {:error, err} ->
        IO.inspect(err)
    end
  end
end
