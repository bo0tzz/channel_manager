defmodule ChannelManager.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    config = Application.fetch_env!(:channel_manager, :config)

    children = [
      ExGram,
      {ChannelManager.Api.Telegram.Server, config["telegram"]},
      {ChannelManager.Api.Telegram, [method: :polling, token: config["telegram"]["token"]]},
      {ChannelManager.Api.Reddit.Server, config["reddit"]},
      {ChannelManager.Forwarder.Supervisor, config["forwarders"]}
    ]

    opts = [strategy: :one_for_one, name: ChannelManager]
    Supervisor.start_link(children, opts)
  end
end
