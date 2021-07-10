defmodule ChannelManager.Forwarder.Source.Reddit do
  require Logger

  alias ChannelManager.Forwarder.Source
  alias ChannelManager.Api.Reddit.OAuth
  alias ChannelManager.Api.Reddit

  @behaviour Source

  @impl Source
  def init(%Source{type: "reddit", source: subreddits}) do
    auth = %OAuth{
      client_id: Application.fetch_env!(:channel_manager, :reddit_client_id),
      client_secret: Application.fetch_env!(:channel_manager, :reddit_client_secret)
    }

    seen_upto =
      Enum.map(subreddits, &String.replace(&1, ~r"^/?r/", ""))
      |> Enum.map(&String.trim/1)
      |> Enum.map(&{&1, ""})

    %{
      auth: auth,
      known_posts: [],
      seen_upto: seen_upto
    }
  end

  @impl Source
  def get_posts(%Source{type: "reddit", rules: rules}, state) do
    {posts, state} = update_posts(state)
    {approved, known_posts} = ChannelManager.Filter.filter_posts(rules, posts)
    Logger.debug("Approved #{length(approved)} reddit posts, remembering #{length(known_posts)}")

    {approved, %{state | known_posts: known_posts}}
  end

  defp update_posts(%{auth: auth, known_posts: known_posts, seen_upto: seen_upto} = state) do
    {token, auth} = OAuth.get_token(auth)

    known_posts =
      case known_posts do
        [] ->
          []

        posts ->
          Enum.map(posts, fn post -> post.id end)
          |> Reddit.bulk(token)
      end

    Logger.debug("#{length(known_posts)} known reddit posts")

    {new_posts, seen_upto} =
      Enum.map(seen_upto, &new_posts(&1, token))
      |> Enum.unzip()

    Logger.debug("Got #{length(new_posts)} new reddit posts")

    {List.flatten([known_posts | new_posts]), %{state | auth: auth, seen_upto: seen_upto}}
  end

  defp new_posts({subreddit, before}, token) do
    posts = Reddit.new(token, subreddit, before)

    new_before =
      case posts do
        [%ChannelManager.Model.Post{id: id} | _] -> id
        _ -> before
      end

    {posts, {subreddit, new_before}}
  end
end
