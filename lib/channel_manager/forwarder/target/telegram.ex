defmodule ChannelManager.Forwarder.Target.Telegram do
  require Logger

  alias ChannelManager.Forwarder.Target
  @behaviour Target

  @impl Target
  def send(%Target{type: "telegram", target: target, options: options}, post) do
    message =
      ChannelManager.Api.Telegram.send_post(
        %ChannelManager.Model.Post{post | votes: 0},
        target,
        options
      )

    ChannelManager.Api.Telegram.Messages.add(message)
  end
end
