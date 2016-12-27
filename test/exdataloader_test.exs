defmodule ExdataloaderTest do
  use ExUnit.Case
  doctest Exdataloader

  def handle_batch(:users_by_id, keys) do
    Enum.map(keys, &({&1, "user:#{&1}"}))
    |> Enum.into(%{})
  end

  def handle_batch(:groups_by_id, keys) do
    Enum.map(keys, &{&1, "group:#{&1}"})
    |> Enum.into(%{})
  end

  test "loads data for a single key" do
    {:ok, pid} = Exdataloader.start_link(&handle_batch/2)
    task = Exdataloader.load(pid, :users_by_id, 1)

    Exdataloader.execute(pid)

    assert Task.await(task) == {:ok, "user:1"}
  end

  test "loads data for multiple keys" do
    {:ok, pid} = Exdataloader.start_link(&handle_batch/2)
    t1 = Exdataloader.load(pid, :users_by_id, 1)
    t2 = Exdataloader.load(pid, :users_by_id, 2)

    Exdataloader.execute(pid)

    assert Task.await(t1) == {:ok, "user:1"}
    assert Task.await(t2) == {:ok, "user:2"}
  end

  test "loads data for multiple loaders" do
    {:ok, pid} = Exdataloader.start_link(&handle_batch/2)
    user1_task = Exdataloader.load(pid, :users_by_id, 1)
    user2_task = Exdataloader.load(pid, :users_by_id, 2)
    group1_task = Exdataloader.load(pid, :groups_by_id, 1)
    group2_task = Exdataloader.load(pid, :groups_by_id, 2)

    Exdataloader.execute(pid)

    assert Task.await(user1_task) == {:ok, "user:1"}
    assert Task.await(user2_task) == {:ok, "user:2"}
    assert Task.await(group1_task) == {:ok, "group:1"}
    assert Task.await(group2_task) == {:ok, "group:2"}
  end
end
