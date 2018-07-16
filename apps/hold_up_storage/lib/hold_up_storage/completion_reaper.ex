defmodule HoldUpStorage.CompletionReaper do
  use GenServer
  use Timex
  alias HoldUpStorage.{Tasks, CompletionSupervisor, CompletionReaper, CompletionReaperRegistry}

  def start_link(state) do
    GenServer.start_link(__MODULE__, state)
  end

  def reap_and_terminate(task_name) do
    # COULD I INSTEAD JUST DELETE THE COMPLETION FROM :MNESIA
    # AND JUST FORGET THE REAPER AND LET IT DIE?
    case existing_reaper(task_name) do
      [{old_reaper, _}] ->
        send(old_reaper, :reap)
        remove_existing_reaper(task_name)
      _ -> nil
    end
  end

  def reap(task_name) do
    {:ok, _} = DynamicSupervisor.start_child(
      CompletionSupervisor,
      Supervisor.child_spec({CompletionReaper, [%{task_name: task_name}]}, restart: :transient)
    )
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
    {:stop, :normal, state}
  end

  def register(task_name) do
    # We use this registry to look up previously created reaper processes
    # that we don't want running anymore. (because the completion has been extended or rewritten or whatever)
    # This kills them off which will automatically remove them from the registry.
    remove_existing_reaper(task_name)
    Registry.register(CompletionReaperRegistry, task_name, {})
  end

  def remove_existing_reaper(task_name) do
    case existing_reaper(task_name) do
      [{old_reaper, _}] ->
        Process.exit(old_reaper, {:shutdown, :new_reaper_registered})
      _ -> nil
    end
  end

  def existing_reaper(task_name) do
    Registry.lookup(CompletionReaperRegistry, task_name)
  end
end
