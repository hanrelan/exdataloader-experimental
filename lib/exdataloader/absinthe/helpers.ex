defmodule Exdataloader.Absinthe.Helpers do

  def load(_, _, _, _opts \\ [])

  def load(%{context: %{dataloader: pid}}, loader, key, opts) do
    load(pid, loader, key, opts)
  end
  
  def load(pid, loader, key, opts) when is_pid(pid) do
    task = Exdataloader.load(pid, loader, key)
    {:plugin, Exdataloader.Absinthe.Plugin, {task, pid, opts}}
  end

end
