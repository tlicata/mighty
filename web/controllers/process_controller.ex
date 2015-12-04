defmodule Mighty.ProcessController do
  use Mighty.Web, :controller

  def index(conn, _params) do
    results = map([1,2,3,4,5], fn(n) -> n * 10 end)
    render conn, "index.html", results: results
  end

  defp map(collection, fun) do
    parent = self()

    processes = Enum.map(collection, fn(item) ->
      spawn_link(fn ->
        send(parent, {self(), fun.(item)})
      end)
    end)

    Enum.map(processes, fn(pid) ->
      receive do
        {^pid, result} -> result
      end
    end)
  end
end
