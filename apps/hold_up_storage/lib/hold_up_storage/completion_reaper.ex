require IEx

defmodule HoldUpStorage.CompletionReaper do
  use GenServer
  use Timex
  alias HoldUpStorage.Tasks

  def start_link(state) do
    GenServer.start_link(__MODULE__, state)
  end

  def reap(server) do
    send(server, :reap)
  end

  def init([state] = [%{task_name: task_name}]) do
    # re-retrieve the TTL when we init this process.
    # This allows us to correctly restart after a crash
    {:ok, ttl} = Tasks.get_task_ttl(task_name)
    timer = Process.send_after(self(), :reap, Duration.to_milliseconds(ttl, truncate: true))
    {:ok, Map.put(state, :timer, timer)}
  end

  def handle_info(:reap, state = %{task_name: task_name}) do
    completion_delete = fn -> :mnesia.delete({Completions, task_name}) end
    {:atomic, :ok} = :mnesia.transaction(completion_delete)
    {:noreply, state}
  end
end
