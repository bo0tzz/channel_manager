defmodule ChannelManager.Forwarder.Target.Telegram do
  require Logger

  alias ChannelManager.Forwarder.Target
  @behaviour Target

  @impl Target
  def send(%Target{type: "telegram", target: target, options: options}, post) do
    ChannelManager.Api.Telegram.send_post(
      %ChannelManager.Model.Post{post | votes: 0},
      target,
      options
    )
    |> case do
      {:ok, msg} -> ChannelManager.Api.Telegram.Messages.add(msg)
      _ -> nil
    end
  end
end
