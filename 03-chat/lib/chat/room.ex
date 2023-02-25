defmodule Chat.Room do
  use GenServer

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @spec join(pid(), String.t()) :: :ok | {:error, atom()}
  def join(pid, name) do
    GenServer.call(Chat.Room, {:join, pid, name})
  end

  @spec leave(pid()) :: :ok
  def leave(pid) do
    GenServer.call(Chat.Room, {:leave, pid})
  end

  @spec broadcast(pid(), String.t()) :: :ok
  def broadcast(from_pid, message) do
    GenServer.cast(Chat.Room, {:broadcast, from_pid, message})
  end

  @impl true
  def init(:ok) do
    {:ok, %{members: %{}}}
  end

  # allow duplicate names
  @impl true
  def handle_call({:join, pid, name}, _from, %{members: members} = state) do
    IO.puts "got here"
    Process.monitor(pid) # monitor the process for exit signals
    Enum.each(members, fn {pid, _name} ->
      send(pid, "* #{name} has joined the room")
    end)
    member_names = Map.values(members)
    msg = "* present: #{Enum.join(member_names, ", ")}"
    IO.puts "sending '#{msg}' to #{inspect pid}"
    send(pid, msg)
    {:reply, :ok, %{state | members: Map.put(state.members, pid, name)}}
  end

  @impl true
  def handle_call({:leave, pid}, _from, state) do
    {:reply, :ok, %{state | members: Map.delete(state.members, pid)}}
  end

  @impl true
  def handle_cast({:broadcast, from_pid, message}, %{members: members} = state) do
    sender_name = if from_pid == self(), do: "", else: "[#{members[from_pid]}] "
    Enum.each(members, fn {pid, _name} ->
      if pid != from_pid, do: send(pid, "#{sender_name}#{message}")
    end)
    {:noreply, state}
  end

  @impl true
  def handle_info({:DOWN, _ref, :process, pid, _reason}, state) do
    nm = state.members[pid]
    members = Map.delete(state.members, pid)
    Enum.each(members, fn {pid, _name} ->
      send(pid, "* #{nm} has left the room")
    end)
    IO.puts "process #{inspect pid} has exited"
    {:noreply, %{state | members: members}}
  end
end
