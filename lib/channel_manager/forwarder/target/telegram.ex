defmodule ChannelManager.Forwarder.Target.Telegram do
  require Logger

  alias ChannelManager.Forwarder.Target
  @behaviour Target

  @impl Target
  def send(%Target{type: "telegram", target: target, options: options}, post) do
    ChannelManager.Api.Telegram.send_post(post, target, Map.get(options, "captions", false))
  end
end
