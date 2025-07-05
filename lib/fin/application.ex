defmodule Fin.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      FinWeb.Telemetry,
      Fin.Repo,
      {DNSCluster, query: Application.get_env(:fin, :dns_cluster_query) || :ignore},
      {Oban, Application.fetch_env!(:fin, Oban)},
      {Phoenix.PubSub, name: Fin.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Fin.Finch},
      # Start a worker by calling: Fin.Worker.start_link(arg)
      # {Fin.Worker, arg},
      # Start to serve requests, typically the last entry
      FinWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Fin.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    FinWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
