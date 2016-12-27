defmodule Exdataloader do
  use GenServer

  defmodule State do
    defstruct keys_per_loader: %{}, listeners_per_loader: %{}, batch_fun: nil
  end

  # Client


  def start_link(batch_fun) do
    GenServer.start_link(__MODULE__, batch_fun)
  end

  def load(pid, loader, key) do
    task = Task.async(fn -> 
      receive do
        {^pid, value} -> value
      end
    end)
    GenServer.cast(pid, {:load, {loader, key}, task.pid})
    task
  end

  def execute(pid) do
    GenServer.cast(pid, {:execute})
  end

  # Server (callbacks)

  def init(batch_fun) do
    {:ok, %State{batch_fun: batch_fun}}
  end

  def handle_cast({:load, {loader, key}, reply_to_pid}, %State{} = state) do
    keys = Map.get(state.keys_per_loader, loader, []) 
    keys_per_loader = Map.put(state.keys_per_loader, loader, [key | keys])
    listeners = Map.get(state.listeners_per_loader, loader, [])
    listeners_per_loader = Map.put(state.listeners_per_loader, loader, [{reply_to_pid, key} | listeners])
    {:noreply, %State{state | keys_per_loader: keys_per_loader, listeners_per_loader: listeners_per_loader}}
  end

  def handle_cast({:execute}, %State{} = state) do
    Enum.each(state.keys_per_loader, fn({loader, keys}) ->
      values = state.batch_fun.(loader, keys)
      Enum.each(state.listeners_per_loader[loader], fn({reply_to_pid, key}) ->
        value = Map.get(values, key, nil)
        send(reply_to_pid, {self, {:ok, value}})
      end) 
    end)
    {:noreply, %State{state | keys_per_loader: %{}, listeners_per_loader: %{}}}
  end

end
