defmodule CraftingSoftwareJobProcessingChallenge.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      CraftingSoftwareJobProcessingChallengeWeb.Telemetry,
      {DNSCluster,
       query:
         Application.get_env(:crafting_software_job_processing_challenge, :dns_cluster_query) ||
           :ignore},
      {Phoenix.PubSub, name: CraftingSoftwareJobProcessingChallenge.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: CraftingSoftwareJobProcessingChallenge.Finch},
      # Start a worker by calling: CraftingSoftwareJobProcessingChallenge.Worker.start_link(arg)
      # {CraftingSoftwareJobProcessingChallenge.Worker, arg},
      # Start to serve requests, typically the last entry
      CraftingSoftwareJobProcessingChallengeWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: CraftingSoftwareJobProcessingChallenge.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    CraftingSoftwareJobProcessingChallengeWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
