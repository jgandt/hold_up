defmodule HoldUpStorage.CompletionReaper do
  use GenServer
  use Timex
  alias HoldUpStorage.{Tasks, CompletionReaperRegistry}

  def start_link(state) do
    GenServer.start_link(__MODULE__, state)
  end

  def reap(server) do
    send(server, :reap)
  end

  def init([state] = [%{task_name: task_name}]) do
    register(task_name)
    {:ok, ttl} = Tasks.get_task_ttl(task_name)
    # This timer gets automatically removed once the process dies
    Process.send_after(self(), :reap, Duration.to_milliseconds(ttl, truncate: true))
    {:ok, state}
  end

  def handle_info(:reap, state = %{task_name: task_name}) do
    completion_delete = fn -> :mnesia.delete({Completions, task_name}) end
    {:atomic, :ok} = :mnesia.transaction(completion_delete)
    {:stop, :shutdown, state}
  end

  def register(task_name) do
    # We use this registry to look up previously created reaper processes
    # that we don't want running anymore. (because the completion has been extended or rewritten or whatever)
    # This kills them off which will automatically remove them from the registry.
    case Registry.lookup(CompletionReaperRegistry, task_name) do
      [{old_reaper, _}] ->
        Process.exit(old_reaper, {:shutdown, :new_reaper_registered})
      _ -> nil
    end
    Registry.register(CompletionReaperRegistry, task_name, {})
  end
end
