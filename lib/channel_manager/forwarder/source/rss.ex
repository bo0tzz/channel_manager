defmodule ChannelManager.Forwarder.Source.RSS do
  alias ChannelManager.Forwarder.Source
  @behaviour Source

  @impl Source
  def init(%Source{type: "rss"} = cfg) do
    %{seen_upto: nil, config: cfg}
  end

  @impl Source
  def get_posts(%{config: %Source{type: "rss", rules: rules} = config} = state) do
    posts = read_feed(config)
    {posts, state} = remove_seen(posts, state)
    {approved, _, _} = ChannelManager.Filter.filter_posts(rules, posts)

    {approved, state}
  end

  defp read_feed(%Source{source: source}) do
    {:ok, response} = Tesla.get(source)
    {:ok, feed} = ElixirFeedParser.parse(response.body)

    Enum.map(feed.entries, &ChannelManager.Model.Post.from_rss/1)
  end

  defp remove_seen(posts, %{seen_upto: id} = state) do
    {new_posts, _seen} =
      case id do
        nil -> {[], []}
        id -> Enum.split_while(posts, fn post -> post.id != id end)
      end

    state =
      case posts do
        [%ChannelManager.Model.Post{id: id} | _] -> %{state | seen_upto: id}
        [] -> state
      end

    {new_posts, state}
  end
end
