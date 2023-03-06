defmodule Database do
  @port 9999
  @version "Mikes Database V1"

  def run do
    {:ok, socket} = :gen_udp.open(@port, [:binary, active: false])
    IO.puts "Listening on port #{@port}"
    loop(socket, %{})
  end

  def loop(socket, state) do
    {:ok, {ip, port, msg}} = :gen_udp.recv(socket, 0)
    cmd = parse(msg)
    {response, new_state} = execute(cmd, state)
    :gen_udp.send(socket, {ip, port}, response)
    loop(socket, new_state)
  end

  def parse(msg) do
    case String.split(msg, "=", parts: 2) do
      [key, value] -> {:set, key, value}
      [key] -> {:get, key}
    end
  end

  def execute({:set, key, value}, state) do
    {value, Map.put(state, key, value)}
  end

  def execute({:get, "version"}, state) do
    {@version, state}
  end

  def execute({:get, key}, state) do
    {Map.get(state, key, ""), state}
  end
end

Database.run()
