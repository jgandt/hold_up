defmodule HoldUpStorage.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  alias HoldUpStorage.Mnesia

  def start(_type, _args) do
    Mnesia.setup
    Mnesia.build_tables

    # List all child processes to be supervised
    children = [
      # Starts a worker by calling: HoldUpStorage.Worker.start_link(arg)
      # {HoldUpStorage.Worker, arg},
      HoldUpStorage.Store,
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: HoldUpStorage.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
