defmodule ChannelManager.Forwarder.Source.Telegram do
  require Logger

  alias ChannelManager.Forwarder.Source

  @behaviour Source

  @impl Source
  def init(%Source{type: "telegram", source: chat_id} = cfg) do
    ChannelManager.Api.Telegram.Messages.track_chat(chat_id)
    cfg
  end

  @impl Source
  def get_posts(%Source{type: "telegram", source: chat_id, rules: rules}, state) do
    posts = ChannelManager.Api.Telegram.Messages.get_all(chat_id)
    {approved, _, denied} = ChannelManager.Filter.filter_posts(rules, posts)

    Enum.each(denied, &ChannelManager.Api.Telegram.Messages.remove/1)
    Enum.each(approved, &ChannelManager.Api.Telegram.Messages.remove/1)

    # TODO: Optionally delete posts

    {approved, state}
  end
end
