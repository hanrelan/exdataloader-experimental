defmodule Exdataloader.Absinthe.Plugin do
  @behaviour Absinthe.Resolution.Plugin

  
  # Set the list of pids to call execute on to empty
  def before_resolution(acc) do
    Map.put(acc, __MODULE__, MapSet.new)
  end

  def init({task, pid, opts}, acc) do
    pids = Map.get(acc, __MODULE__, MapSet.new)
           |> MapSet.put(pid)
    {{task, opts}, Map.put(acc, __MODULE__, pids)}
  end

  def after_resolution(%{__MODULE__ => pids = %MapSet{}} = acc) do
    Enum.each(pids, fn(pid) -> Exdataloader.execute(pid) end)
    acc
  end
  def after_resolution(acc), do: acc

  def pipeline(pipeline, %{__MODULE__ => pids = %MapSet{}}) do
    if MapSet.size(pids) > 0 do
      [Absinthe.Phase.Document.Execution.Resolution | pipeline]
    else
      pipeline
    end
  end
  def pipeline(pipeline, _acc) do
    pipeline
  end

  def resolve({task, opts}, acc) do
    {Task.await(task, Keyword.get(opts, :timeout, 30_000)), acc}
  end

end
