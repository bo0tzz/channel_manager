defmodule ChannelManager.Forwarder.Supervisor do
  use Supervisor

  def start_link(arg) do
    Supervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  @impl true
  def init(forwarders) do
    Enum.map(forwarders, &{ChannelManager.Forwarder.Server, [&1]})
    |> Supervisor.init(strategy: :one_for_one)
  end
end
