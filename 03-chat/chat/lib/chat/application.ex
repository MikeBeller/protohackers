defmodule Chat.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @port 9999

  @impl true
  def start(_type, _args) do
    children = [
      {Task.Supervisor, name: Chat.TaskSupervisor},
      {Chat.Room, []},
      {Chat.Server, [@port]},
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Chat.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
