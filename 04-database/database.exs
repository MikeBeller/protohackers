defmodule Database do
  @port 9999
  @version "Mikes Database V1"

  def run do
    {:ok, socket} = :gen_udp.open(@port, [:binary, active: false, ip: {0, 0, 0, 0}])
    IO.puts "Listening on port #{@port}"
    loop(socket, %{})
  end

  defp parse(msg) do
    case String.split(msg, "=", parts: 2) do
      [key, value] -> {:set, key, value}
      [key] -> {:get, key}
    end
  end

  def loop(socket, state) do
    {:ok, {ip, port, msg}} = :gen_udp.recv(socket, 0)
    msg = String.trim(msg)
    IO.puts "Received #{msg} from #{inspect ip}:#{port}"
    case parse(msg) do
      {:set, key, value} ->
        loop(socket, Map.put(state, key, value))
      {:get, key} ->
        response = key <> "=" <> case key do
          "version" -> @version
          _ -> Map.get(state, key, "")
        end
        IO.puts "Responding with #{response}"
        :gen_udp.send(socket, {ip, port}, response)
        loop(socket, state)
    end
  end
end

Database.run()
