defmodule Chat.Channel do

  defp valid_name?(name) do
    String.length(name) > 0 && String.length(name) < 20
      && String.match?(name, ~r/^[a-zA-Z0-9]+$/)
  end

  def serve_client(sock) do
    :gen_tcp.send(sock, "name?\n")
    {:ok, name} = :gen_tcp.recv(sock, 0)
    name = String.trim(name)
    if valid_name?(name) do
      IO.puts "setting name to #{name} in #{inspect self()}"
      :inet.setopts(sock, active: true)
      :ok = Chat.Room.join(self(), name)
      loop(sock)
    end
  end

  def loop(sock) do
    receive do
      {:tcp, _sock, msg} ->
        IO.puts "received: #{msg}"
        msg = String.trim(msg)
        Chat.Room.broadcast(self(), msg)
        loop(sock)
      {:chat, msg} ->
        :gen_tcp.send(sock, msg)
        loop(sock)
      msg ->
        IO.puts "UNCAUGHT MESSAGE: #{inspect msg}"
        loop(sock)
    end
  end
end
