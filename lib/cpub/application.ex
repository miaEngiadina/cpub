defmodule CPub.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  alias CPub.Web.Endpoint

  @spec start(Application.start_type(), term) ::
          {:ok, pid} | {:ok, pid, Application.state()} | {:error, term}
  def start(_type, _args) do
    children = [
      CPub.Repo,
      CPub.Web.Endpoint,
      CPub.Database

      # Start the PubSub system
      # {Phoenix.PubSub, name: CPub.PubSub},
    ]

    opts = [strategy: :one_for_one, name: CPub.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @spec config_change(keyword, keyword, [atom]) :: :ok
  def config_change(changed, _new, removed) do
    Endpoint.config_change(changed, removed)

    :ok
  end
end
