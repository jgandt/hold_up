defmodule HoldUpStorage.Completions do
  use Timex
  alias HoldUpStorage.{CompletionReaper, Tasks}

  def incomplete_tasks do
    Tasks.list_tasks() -- completed_tasks()
  end

  def complete_task(task_name) do
    {:ok, ttl} = Tasks.get_task_ttl(task_name)
    {:atomic, :ok} = :mnesia.transaction(
      fn ->
        :mnesia.write({Completions, task_name, ttl})
      end
    )

    # schedule removal job
    CompletionReaper.reap(task_name)
  end

  def init(:ok) do
    {:ok, nil}
  end

  def completed_tasks do
    completion_retrieval = fn ->
      :mnesia.foldl(fn(task, accum) ->
        [elem(task, 1)] ++ accum
      end, [], Completions)
    end

    {:atomic, list} = :mnesia.transaction(completion_retrieval)
    list
  end
end
