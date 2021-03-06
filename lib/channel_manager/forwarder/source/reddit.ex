defmodule ChannelManager.Forwarder.Source.Reddit do
  require Logger

  alias ChannelManager.Forwarder.Source
  alias ChannelManager.Api.Reddit

  @behaviour Source

  @impl Source
  def init(%Source{type: "reddit", source: subreddits} = cfg) do
    seen_upto =
      Enum.map(subreddits, &String.replace(&1, ~r"^/?r/", ""))
      |> Enum.map(&String.trim/1)
      |> Enum.map(&{&1, ""})

    state = %{
      known_posts: [],
      seen_upto: seen_upto,
      config: cfg
    }

    {discarded, state} = get_posts(state)
    Logger.debug("Discarding #{length(discarded)} reddit posts on initialization")

    state
  end

  @impl Source
  def get_posts(%{config: %Source{type: "reddit", rules: rules}} = state) do
    {posts, state} = update_posts(state)
    {approved, known_posts, _} = ChannelManager.Filter.filter_posts(rules, posts)
    Logger.debug("Approved #{length(approved)} reddit posts, remembering #{length(known_posts)}")

    {approved, %{state | known_posts: known_posts}}
  end

  defp update_posts(%{known_posts: known_posts, seen_upto: seen_upto} = state) do
    known_posts =
      case known_posts do
        [] ->
          []

        posts ->
          Enum.map(posts, fn post -> post.id end)
          |> Reddit.bulk()
      end

    Logger.debug("#{length(known_posts)} known reddit posts")

    {new_posts, seen_upto} = load_new(seen_upto)
    new_posts = List.flatten(new_posts)

    Logger.debug("Got #{length(new_posts)} new reddit posts")

    {List.flatten([known_posts | new_posts]), %{state | seen_upto: seen_upto}}
  end

  defp load_new(seen_upto) do
    Enum.map(seen_upto, &new_posts/1)
    |> Enum.unzip()
  end

  defp new_posts({subreddit, before}) do
    posts = Reddit.new(subreddit, before)

    new_before =
      case posts do
        [%ChannelManager.Model.Post{id: id} | _] -> id
        _ -> before
      end

    {posts, {subreddit, new_before}}
  end
end
