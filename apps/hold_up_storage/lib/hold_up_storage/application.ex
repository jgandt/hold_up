defmodule HoldUpStorage.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  alias HoldUpStorage.Tables

  def start(_type, _args) do
    Tables.setup
    Tables.build_tables

    # List all child processes to be supervised
    children = [
      # Starts a worker by calling: HoldUpStorage.Worker.start_link(arg)
      HoldUpStorage.Supervisor
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one]
    Supervisor.start_link(children, opts)
  end
end
