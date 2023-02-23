defmodule Chat.Room do
  use GenServer

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @spec join(String.t(), pid()) :: :ok | {:error, symbol()}
  def join(name, pid) do
    GenServer.call(Chat.Room, {:join, name, pid})
  end

  def leave(name) do
    GenServer.call(Chat.Room, {:leave, name})
  end

  def broadcast(from_pid, message) do
    GenServer.cast(Chat.Room, {:broadcast, from_pid, message})
  end

  @impl true
  def init(:ok) do
    {:ok, %{members: %{}}}
  end

  @impl true
  def handle_call({:join, name, pid}, _from, %{members: members} = state) do
    case Map.fetch(members, name) do
      {:ok, _} ->
        {:reply, {:error, :already_joined}, state}
      :error ->
        members = Map.put(state.members, name, pid)
        member_names = Map.keys(members)
        send(pid, "* present: #{Enum.join(member_names, ", ")}")
        broadcast(pid, "* #{name} has joined the room")
        {:reply, :ok, %{state | members: members}}
    end
  end

  @impl true
  def handle_call({:leave, name}, _from, state) do
    {:reply, :ok, %{state | members: MapSet.delete(state.members, name)}}
  end

  @impl true
  def handle_cast({:broadcast, from_pid, message}, state) do
    Enum.each(state.members, fn pid ->
      if pid != from_pid, do: send(pid, message)
    end)

    {:noreply, state}
  end
end
