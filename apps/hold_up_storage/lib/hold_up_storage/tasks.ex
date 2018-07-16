defmodule HoldUpStorage.Tasks do
  use Timex
  alias HoldUpStorage.Completions

  def list_tasks do
    task_retrieval = fn ->
      :mnesia.foldl(fn(task, accum) ->
        [elem(task, 1)] ++ accum
      end, [], Tasks)
    end

    {:atomic, list} = :mnesia.transaction(task_retrieval)
    list
  end

  def get_task_ttl(task_name) do
    case find_task(task_name) do
      {:ok, {_task_name, ttl}} -> {:ok, ttl}
      _ -> {:error, :task_not_found}
    end
  end

  def find_task(task_name) do
    # This could just be a read from the tasks Map.
    # mnesia is only being used for persistence across reboots
    read_task = fn -> :mnesia.read({Tasks, task_name}) end
    return_val = case :mnesia.transaction(read_task) do
      {:atomic, []} -> {:error, :not_found}
      {:atomic, [{Tasks, ^task_name, ttl}]} -> {:ok, {task_name, ttl}}
    end

    return_val
  end

  def add_task(task_name, ttl = %Duration{}) do
    {:atomic, :ok} = :mnesia.transaction(
      fn ->
        :mnesia.write({Tasks, task_name, ttl})
      end
    )
    Completions.uncomplete_task(task_name)
  end
end
