defmodule ChannelManager.Forwarder.Source.RSS do
  alias ChannelManager.Forwarder.Source

  def init(%Source{type: "rss"} = source) do
    {source, %{seen_upto: nil}}
  end

  def get_posts({%Source{type: "rss", rules: rules} = config, state}) do
    posts = read_feed(config)
    {posts, state} = remove_seen(posts, state)
    {approved, _} = ChannelManager.Filter.filter_posts(rules, posts)

    {approved, {config, state}}
  end

  defp read_feed(%Source{source: source}) do
    {:ok, response} = Tesla.get(source)
    {:ok, feed} = ElixirFeedParser.parse(response.body)

    Enum.map(feed.entries, &ChannelManager.Model.Post.from_rss/1)
  end

  defp remove_seen(posts, %{seen_upto: id} = state) do
    {posts, _seen} = Enum.split_while(posts, fn post -> post.id != id end)

    state =
      case posts do
        [%ChannelManager.Model.Post{id: id} | _] -> %{state | seen_upto: id}
        [] -> state
      end

    {posts, state}
  end
end
