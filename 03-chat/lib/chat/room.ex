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

  defp do_leave(pid, %{members: members} = state) do
    case Map.fetch(members, pid) do
      {:ok, name} ->
        members = Map.delete(state.members, pid)
        Enum.each(members, fn {pid, _name} ->
          send(pid, {:chat, "* #{name} has left the room"})
        end)
        %{state | members: members}
      _ -> state
    end
  end

  @impl true
  def init(:ok) do
    Process.flag(:trap_exit, true)
    {:ok, %{members: %{}}}
  end

  # allow duplicate names
  @impl true
  def handle_call({:join, pid, name}, _from, %{members: members} = state) do
    Process.link(pid) # monitor the process for exit signals
    Enum.each(members, fn {pid, _name} ->
      send(pid, {:chat, "* #{name} has joined the room"})
    end)
    member_names = Map.values(members)
    msg = "* present: #{Enum.join(member_names, ", ")}"
    {:reply, {:ok, msg}, %{state | members: Map.put(state.members, pid, name)}}
  end

  @impl true
  def handle_call({:leave, pid}, _from, state) do
    state = do_leave(pid, state)
    {:reply, :ok, state}
  end

  @impl true
  def handle_cast({:broadcast, from_pid, message}, %{members: members} = state) do
    sender_name = if from_pid == self(), do: "", else: "[#{members[from_pid]}] "
    Enum.each(members, fn {pid, _name} ->
      if pid != from_pid, do: send(pid, {:chat, "#{sender_name}#{message}"})
    end)
    {:noreply, state}
  end

  @impl true
  def handle_info({:EXIT, pid, _reason}, state) do
    state = do_leave(pid, state)
    {:noreply, state}
  end
end
