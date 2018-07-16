defmodule HoldUpStorage.Completions do
  use Timex
  alias HoldUpStorage.{CompletionReaper, Tasks}

  def incomplete_tasks do
    Tasks.list_tasks() -- completed_tasks()
  end

  def complete_task(task_name) do
    # SOMETHING WAS GOING WRONG HERE.

    # COME UP WITH BETTER TEST CASES.
    #   ADD TASK WITH DURATION.
    #   COMPLETE TASK
    #   RE-ADD TASK WITH DURATION.
    #   RE-COMPLETE TASK
    #   BE SURE TASK IS INCOMPLETE WHEN THE SECOND DURATION EXPIRES.


    {:ok, ttl} = Tasks.get_task_ttl(task_name)
    {:atomic, :ok} = :mnesia.transaction(
      fn ->
        :mnesia.write({Completions, task_name, ttl})
      end
    )

    # schedule removal job
    CompletionReaper.reap(task_name)
  end

  # def uncomplete_task(task_name) do
  #   CompletionReaper.reap_and_terminate(task_name)
  # end

  def init(:ok) do
    # ON INIT schedule removal tasks for all entries in Completions
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
