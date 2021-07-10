defmodule ChannelManager.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    config = Application.fetch_env!(:channel_manager, :config)
    forwarders = Enum.map(config["forwarders"], &ChannelManager.Forwarder.from_map/1)

    children = [
      ExGram,
      {ChannelManager.Api.Telegram, [method: :polling, token: config["telegram"]["token"]]},
      {ChannelManager.Api.Reddit.Server, config["reddit"]},
      {ChannelManager.Forwarder.Supervisor, forwarders}
    ]

    opts = [strategy: :one_for_one, name: ChannelManager]
    Supervisor.start_link(children, opts)
  end
end
