defmodule HoldUpStorage.Supervisor do
  use Supervisor

  def start_link([]) do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init([]) do
    children = [
      HoldUpStorage.CompletionSupervisor,
      {Registry, keys: :unique, name: HoldUpStorage.CompletionReaperRegistry}
    ]

    # supervise/2 is imported from Supervisor.Spec
    Supervisor.init(children, strategy: :one_for_one)
  end
end
