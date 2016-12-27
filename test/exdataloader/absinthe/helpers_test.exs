defmodule Exdataloader.Absinthe.HelpersTest do
  use ExUnit.Case, async: true

  alias Exdataloader.Absinthe.Helpers

  defmodule Schema do
    use Absinthe.Schema

    def resolution_plugins do
      [Exdataloader.Absinthe.Plugin]
    end

    query do
      field :user, :string do
        arg :id, type: :integer
        resolve fn(%{id: id}, context) ->
          Helpers.load(context, :users_by_id, id)
        end
      end

      field :member, :string do
        arg :id, type: :integer
        resolve fn(%{id: id}, %{context: %{dataloader: pid}}) ->
          Helpers.load(pid, :users_by_id, id)
        end
      end
    end

  end

  def handle_batch(:users_by_id, keys) do
    Enum.map(keys, &{&1, "user:#{&1}"})
    |> Enum.into(%{})
  end

  test "helper resolves when passed the context" do
    {:ok, pid} = Exdataloader.start_link(&handle_batch/2)
    query = """
    {
      user(id: 1)
    }
    """
    assert Absinthe.run(query, Schema, context: %{dataloader: pid}) == {:ok, %{data: %{"user" => "user:1"}}}
  end

  test "helper resolves when passed the pid" do
    {:ok, pid} = Exdataloader.start_link(&handle_batch/2)
    query = """
    {
      member(id: 1)
    }
    """
    assert Absinthe.run(query, Schema, context: %{dataloader: pid}) == {:ok, %{data: %{"member" => "user:1"}}}
  end

end
