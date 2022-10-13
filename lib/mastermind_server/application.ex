defmodule MastermindServer.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Task.Supervisor, name: MastermindServer.TaskSupervisor},
      Supervisor.child_spec({Task, fn -> MastermindServer.accept(4040) end}, restart: :permanent)
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: MastermindServer.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
