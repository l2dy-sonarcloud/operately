defmodule TurboConnect.QueryTest do
  use ExUnit.Case

  defmodule ExampleQuery do
    use TurboConnect.Query

    inputs do
      field? :id, :string
    end

    outputs do
      field? :id, :string
      field? :name, :string
      field? :hobbies, list_of(:string)
    end

    def call(inputs) do
      res = %{id: inputs.id, name: "Example"}

      {:ok, res}
    end
  end

  test "defining a query with inputs and outputs" do
    assert ExampleQuery.__inputs__() == %{
             fields: [
               {:id, :string, [optional: true]}
             ]
           }

    assert ExampleQuery.__outputs__() == %{
             fields: [
               {:id, :string, [optional: true]},
               {:name, :string, [optional: true]},
               {:hobbies, {:list, :string}, [optional: true]}
             ]
           }
  end
end
