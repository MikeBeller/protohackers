defmodule Chat.Server do
    use GenServer

    def start_link({ip, port}) do
        GenServer.start_link(__MODULE__, [ip, port], [])
    end

    def init(ip, port) do
        {:ok, server_sock} = :gen_tcp.listen(port, [:binary, packet: line, active: false, ip: ip])
        IO.puts "Accepting connections on port #{port}"
        _task = Task.start(fn -> loop_acceptor(sock) end)
        {:ok, %{ip: ip, port: port, server: server_sock}}
    end

    defp loop_acceptor(sock) do
        case :gen_tcp.accept(sock) do
          {:ok, client} ->
            Task.start(fn -> serve_client(client) end)
            loop_acceptor(sock)
          {:error, :eagain} ->
            loop_acceptor(sock)
          {:error, err} ->
            IO.inspect(err)
        end
    end


  defp serve_client(sock, state \\ %{}) do
    case :gen_tcp.recv(sock) do
      {:ok, cmd} ->
        IO.inspect(cmd)
      {:error, :closed} ->
        :gen_tcp.close(sock)
      {:error, err} ->
        IO.inspect(err)
    end
  end
end
