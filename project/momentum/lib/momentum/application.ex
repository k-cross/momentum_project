defmodule Momentum.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      {
        Finch,
        name: Client,
        pools: %{
          default: [
            size: 10,
            count: 1,
            protocol: :http1,
            max_idle_time: :infinity,
            conn_opts: [transport_opts: [ciphers: :ssl.cipher_suites(:all, :"tlsv1.2")]]
          ]
        }
      },
      # Start the PubSub system
      {Phoenix.PubSub, name: Momentum.PubSub}
      # Start a worker by calling: Momentum.Worker.start_link(arg)
      # {Momentum.Worker, arg}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Momentum.Supervisor)
  end
end
