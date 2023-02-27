defmodule Chat.Channel do

  defp valid_name?(name) do
    String.length(name) > 0 && String.length(name) < 20
      && String.match?(name, ~r/^[a-zA-Z0-9]+$/)
  end

  defp send_sock(sock, msg) do
    :gen_tcp.send(sock, msg <> "\n")
  end

  def serve_client(sock) do
    send_sock(sock, "name?")
    {:ok, name} = :gen_tcp.recv(sock, 0)
    name = String.trim(name)
    if valid_name?(name) do
      IO.puts "setting name to #{name} in #{inspect self()}"
      {:ok, msg} = Chat.Room.join(self(), name)
      IO.puts "sending msg from channel: #{msg}"
      send_sock(sock, msg)
      :inet.setopts(sock, active: true)
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
        send_sock(sock, msg)
        loop(sock)
      msg ->
        IO.puts "UNCAUGHT MESSAGE: #{inspect msg}"
        loop(sock)
    end
  end
end
