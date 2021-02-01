defmodule Momentum.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      {Finch, name: Client},
      # Start the PubSub system
      {Phoenix.PubSub, name: Momentum.PubSub}
      # Start a worker by calling: Momentum.Worker.start_link(arg)
      # {Momentum.Worker, arg}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Momentum.Supervisor)
  end
end
