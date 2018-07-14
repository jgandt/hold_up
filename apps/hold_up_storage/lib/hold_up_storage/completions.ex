defmodule HoldUpStorage.Completions do
  use GenServer

  def start_link(_args) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def list_incomplete_tasks(server) do
    GenServer.call(server, {:list_incomplete_tasks})
  end

  def complete_task(server, task_name) do
    # Add task to completed
    # schedule removal job
    GenServer.cast(server, {:complete_task, task_name})
  end

  def list_completions do
    []
  end

  def init(:ok) do
    {:ok, list_completions()}
  end

  def handle_call({:list_tasks}, _from, completed_tasks) do
    {:reply, all_task_names(), completed_tasks}
  end

  def handle_call({:list_incomplete_tasks}, _from, completed_tasks) do
    {:reply, all_task_names -- completed_tasks, completed_tasks}
  end

  def handle_cast({:complete_task, task_name}, completed_tasks) do
    {:noreply, completed_tasks ++ [task_name]}
  end

  def handle_call({:find_task, task_name}, _from, completed_tasks) do
    # This could just be a read from the tasks Map.
    # mnesia is only being used for persistence across reboots
    read_task = fn -> :mnesia.read({Task, task_name}) end
    return_val = case :mnesia.transaction(read_task) do
      {:atomic, []} -> {:error, :not_found}
      {:atomic, [{Task, ^task_name, ttl}]} -> {:ok, {task_name, ttl}}
    end

    {:reply, return_val, completed_tasks}
  end

  def handle_cast({:add_task, task_name, ttl}, completed_tasks) do
    {:atomic, :ok} = :mnesia.transaction(
      fn ->
        :mnesia.write({Task, task_name, ttl})
      end
    )
    {:noreply, completed_tasks}
  end
end
