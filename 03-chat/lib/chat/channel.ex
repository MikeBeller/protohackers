defmodule Chat.Channel do
  defp valid_name?(name) do
    String.length(name) > 0 && String.length(name) < 20
      && String.match?(name, ~r/^[a-zA-Z0-9]+$/)
  end

  def serve_client(sock, _state \\ %{}) do
    :gen_tcp.send(sock, "name?\n")
    {:ok, name} = :gen_tcp.recv(sock, 0)
    name = String.trim(name)
    if valid_name?(name) do
      :ok = Chat.Room.join(self(), name)
      :inet.setopts(sock, [active: true, packet: :line])
    end
  end

  def handle_info({:tcp, _sock, msg}, state) do
    msg = String.trim(msg)
    Chat.Room.broadcast(self(), msg)
    {:noreply, state}
  end
end
