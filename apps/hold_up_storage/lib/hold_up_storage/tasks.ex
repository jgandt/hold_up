defmodule HoldUpStorage.Tasks do

  def start_link(_args) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def list_tasks(server) do
    GenServer.call(server, {:list_tasks})
  end

  def list_incomplete_tasks(server) do
    GenServer.call(server, {:list_incomplete_tasks})
  end

  def complete_task(server, task_name) do
    # Add task to completed
    # schedule removal job
    GenServer.cast(server, {:complete_task, task_name})
  end

  def find_task(server, task_name) do
    GenServer.call(server, {:find_task, task_name})
  end

  def add_task(server, task_name, ttl) do
    GenServer.cast(server, {:add_task, task_name, ttl})
  end

  def all_task_names do
    task_retrieval = fn ->
      :mnesia.foldl(fn(task, accum) ->
        [elem(task, 1)] ++ accum
      end, [], Tasks)
    end

    {:atomic, list} = :mnesia.transaction(task_retrieval)
    list
  end

  def init(:ok) do
    {:ok, []}
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
    read_task = fn -> :mnesia.read({Tasks, task_name}) end
    return_val = case :mnesia.transaction(read_task) do
      {:atomic, []} -> {:error, :not_found}
      {:atomic, [{Tasks, ^task_name, ttl}]} -> {:ok, {task_name, ttl}}
    end

    {:reply, return_val, completed_tasks}
  end

  def handle_cast({:add_task, task_name, ttl}, completed_tasks) do
    {:atomic, :ok} = :mnesia.transaction(
      fn ->
        :mnesia.write({Tasks, task_name, ttl})
      end
    )
    {:noreply, completed_tasks}
  end
end
