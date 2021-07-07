defmodule ChannelManager.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      ExGram,
      {ChannelManager, [method: :polling, token: Application.fetch_env!(:channel_manager, :bot_token)]}
    ]

    opts = [strategy: :one_for_one, name: ChannelManager.Supervisor]
    Supervisor.start_link(children, opts)
  end
end