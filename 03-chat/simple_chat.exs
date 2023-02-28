defmodule SimpleChat do
  def run(port) do
    {:ok, server_sock} = :gen_tcp.listen(port, [:binary, active: true, packet: :line, reuseaddr: true])
    parent_pid = self()
    Task.start_link(fn -> loop_accept(server_sock, parent_pid) end)
    main_loop(%{})
  end

  def loop_accept(server_sock, parent_pid) do
    case :gen_tcp.accept(server_sock) do
      {:ok, client_sock} ->
        :gen_tcp.controlling_process(client_sock, parent_pid)
        send(parent_pid, {:connect, client_sock})
        loop_accept(server_sock, parent_pid)
      {:error, :eagain} ->
        loop_accept(server_sock, parent_pid)
      {:error, err} ->
        IO.puts("Accept quit with error: #{inspect err}")
        err
    end
  end

  def main_loop(state) do
    IO.puts("Main loop: #{inspect state}")
    receive do
      {:connect, client_sock} ->
        IO.puts("New client connected: #{inspect client_sock}")
        :gen_tcp.send(client_sock, "name?\n")
        main_loop(Map.put(state, client_sock, :new))
      {:tcp, client_sock, data} ->
        state = handle_data(state, client_sock, data)
        main_loop(state)
      {:tcp_closed, client_sock} ->
        IO.puts("Socket closed")
        state = handle_close(state, client_sock)
        main_loop(state)
      {:tcp_error, client_sock, reason} ->
        IO.puts("Socket error: #{inspect reason}")
        state = handle_close(state, client_sock)
        main_loop(state)
      msg -> IO.puts("Unknown message: #{inspect msg}")
    end
  end

  def handle_data(state, client_sock, data) do
    IO.puts("Data received: #{inspect data}")

    case Map.fetch(state, client_sock) do
      :error ->
        IO.puts("Unknown client: #{inspect client_sock}")
      {:ok, :new} ->
        if valid_name?(data) do
          state = Map.put(state, client_sock, data)
          names = Map.values(state) |> Enum.filter(fn x -> x != :new end) |> Enum.join(", ")
          :gen_tcp.send(client_sock, "* present: #{names}")
          Map.put(state, client_sock, data)
        else
          :gen_tcp.close(client_sock)
          state
      {:ok, name} ->
        state
        |> Enum.each( fn {sock, name} ->
          :gen_tcp.send(sock, "[#{name}] #{data}")
        end)
        state
    end
  end

  def handle_close(state, client_sock) do
    IO.puts("Client disconnected: #{inspect client_sock}")
    Map.delete(state, client_sock)
  end
end

SimpleChat.run(9999)
