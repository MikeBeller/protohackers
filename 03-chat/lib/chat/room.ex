defmodule Chat.Room do
  use GenServer

  def start_link(room_name) do
    GenServer.start_link(__MODULE__, room_name)
  end

  def join(room_name, pid) do
    GenServer.call(room_name, {:join, pid})
  end

  def leave(room_name, pid) do
    GenServer.call(room_name, {:leave, pid})
  end

  def broadcast(room_name, message) do
    GenServer.cast(room_name, {:broadcast, message})
  end

  @impl true
  def init(room_name) do
    {:ok, %{name: room_name, members: MapSet.new()}}
  end

  @impl true
  def handle_call({:join, pid}, _from, state) do
    {:reply, :ok, %{state | members: MapSet.put(state.members, pid)}}
  end

  @impl true
  def handle_call({:leave, pid}, _from, state) do
    {:reply, :ok, %{state | members: MapSet.delete(state.members, pid)}}
  end

  @impl true
  def handle_cast({:broadcast, message}, state) do
    Enum.each(state.members, fn pid ->
      send(pid, message)
    end)

    {:noreply, state}
  end
end
