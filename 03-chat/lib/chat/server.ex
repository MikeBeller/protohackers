defmodule Chat.Server do

    def init(port \\ 9999) do
      {:ok, server_sock} = :gen_tcp.listen(port, [:binary, packet: :line, active: false])
      IO.puts "Accepting connections on port #{port}"
      #_task = Task.start_link(fn -> loop_acceptor(server_sock) end)  # acceptor crash will crash client?
      spawn(fn -> loop_acceptor(server_sock) end)
      {:ok, server_sock}
    end

    def loop_acceptor(sock) do
      case :gen_tcp.accept(sock) do
        {:ok, client} ->
          Task.async(fn -> serve_client(client) end)
          loop_acceptor(sock)
        {:error, :eagain} ->
          loop_acceptor(sock)
        {:error, err} ->
          IO.inspect(err)
      end
    end


  def serve_client(sock, state \\ %{}) do
    case :gen_tcp.recv(sock, 0) do
      {:ok, cmd} ->
        IO.inspect(cmd)
      {:error, :closed} ->
        :gen_tcp.close(sock)
      {:error, err} ->
        IO.inspect(err)
    end
  end
end
