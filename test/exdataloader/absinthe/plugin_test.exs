defmodule Exdataloader.Absinthe.PluginTest do
  use ExUnit.Case, async: true
  

  defmodule Schema do
    use Absinthe.Schema

    def resolution_plugins do
      [Exdataloader.Absinthe.Plugin]
    end

    object :group do
      field :user, :string do
        resolve fn(group, _args, %{context: %{dataloader: pid}}) ->
          task = Exdataloader.load(pid, :users_by_id, group[:user_id])
          {:plugin, Exdataloader.Absinthe.Plugin, {task, pid, []}}
        end
      end
      field :name, :string
    end

    query do
      
      field :user, :string do
        arg :id, type: :integer
        resolve fn(%{id: id}, %{context: %{dataloader: pid}}) ->
          task = Exdataloader.load(pid, :users_by_id, id)
          {:plugin, Exdataloader.Absinthe.Plugin, {task, pid, []}}
        end
      end

      field :group, :group do
        arg :id, type: :integer
        resolve fn(%{id: id}, %{context: %{dataloader: pid}}) ->
          task = Exdataloader.load(pid, :groups_by_id, id)
          {:plugin, Exdataloader.Absinthe.Plugin, {task, pid, []}}
        end
      end

      field :returns_nil, :string do
        resolve fn(_, %{context: %{dataloader: pid}}) ->
          task = Exdataloader.load(pid, :nil_returner, 1)
          {:plugin, Exdataloader.Absinthe.Plugin, {task, pid, []}}
        end
      end

    end

  end

  def handle_batch(:users_by_id, keys) do
    Enum.map(keys, &({&1, "user:#{&1}"}))
    |> Enum.into(%{})
  end

  def handle_batch(:groups_by_id, keys) do
    Enum.map(keys, &{&1, %{name: "group:#{&1}", user_id: &1}})
    |> Enum.into(%{})
  end

  def handle_batch(:nil_returner, keys) do
    Enum.map(keys, &{&1, nil})
    |> Enum.into(%{})
  end

  test "resolves for single key" do
    {:ok, pid} = Exdataloader.start_link(&handle_batch/2)
    query = """
    {
      user(id: 1)
    }
    """
    assert Absinthe.run(query, Schema, context: %{dataloader: pid}) == {:ok, %{data: %{"user" => "user:1"}}}
  end 
  
  test "resolves for multiple keys" do
    {:ok, pid} = Exdataloader.start_link(&handle_batch/2)
    query = """
    {
      u1: user(id: 1)
      u2: user(id: 2)
      group(id: 1) {
        name
      }
    }
    """
    assert Absinthe.run(query, Schema, context: %{dataloader: pid}) == {:ok, %{data: %{"u1" => "user:1", 
                                                                                       "u2" => "user:2", 
                                                                                       "group" => %{"name" => "group:1"}}}}
  end

  test "resolves for nested queries" do
    {:ok, pid} = Exdataloader.start_link(&handle_batch/2)
    query = """
    {
      u1: user(id: 1)
      group(id: 2) {
        name
        user
      }

    }
    """
    assert Absinthe.run(query, Schema, context: %{dataloader: pid}) ==  {:ok, %{data:
                                                                               %{"u1" => "user:1",
                                                                                 "group" => %{"user" => "user:2",
                                                                                  "name" => "group:2"}}}}
                                                                                 
  end

  test "resolves nil correctly" do
    {:ok, pid} = Exdataloader.start_link(&handle_batch/2)
    query = """
    {
      returnsNil
    }
    """
    assert Absinthe.run(query, Schema, context: %{dataloader: pid}) ==  {:ok, %{data: %{"returnsNil" => nil}}}
  end
    
end
