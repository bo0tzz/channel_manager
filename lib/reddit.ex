defmodule Reddit do
  require Logger

  defstruct [
    :subreddits,
    :known_posts,
    :oauth
  ]

  @keys_to_keep ["title", "name", "url", "created_utc", "ups", "post_hint", "is_self"]

  defp send_captions(), do: Application.fetch_env!(:channel_manager, :send_captions)

  defp vote_threshold(),
    do: Integer.parse(Application.fetch_env!(:channel_manager, :reddit_vote_threshold)) |> elem(0)

  defp age_threshold(),
    do: Integer.parse(Application.fetch_env!(:channel_manager, :reddit_age_threshold)) |> elem(0)

  def init() do
    subreddits =
      Application.fetch_env!(:channel_manager, :subreddits)
      |> Enum.map(&{&1, ""})

    oauth = %Reddit.Api.OAuth{
      client_id: Application.fetch_env!(:channel_manager, :reddit_client_id),
      client_secret: Application.fetch_env!(:channel_manager, :reddit_client_secret)
    }

    %Reddit{subreddits: subreddits, known_posts: [], oauth: oauth}
  end

  def trigger_scan(), do: GenServer.cast(Reddit.Server, :scan)

  def discard_scan(%Reddit{subreddits: subreddits} = state) do
    {state, token} = get_token(state)
    {p, subreddits} = get_posts(subreddits, token)
    Logger.debug("Discarding #{length(p)} posts")

    %{state | subreddits: subreddits}
  end

  def do_scan(%Reddit{subreddits: subreddits, known_posts: known_posts} = state) do
    {state, token} = get_token(state)

    known_posts = update_posts(known_posts, token)
    Logger.debug("#{length(known_posts)} known posts")

    {posts, subreddits} = get_posts(subreddits, token)
    Logger.debug("Got #{length(posts)} new posts")

    {send, keep} =
      List.flatten([known_posts | posts])
      |> filter_posts()

    Logger.debug("Sending #{length(send)} posts, keeping #{length(keep)}")

    Enum.each(send, &send_to_channel/1)
    %{state | subreddits: subreddits, known_posts: keep}
  end

  defp update_posts([], _), do: []

  defp update_posts(known_posts, token) do
    names = Enum.map(known_posts, fn post -> post["name"] end)

    Reddit.Api.bulk(token, names)
    |> get_in(["data", "children"])
    |> Enum.map(fn child ->
      child["data"]
    end)
    |> Enum.map(&Map.take(&1, @keys_to_keep))
  end

  defp get_posts(subreddits, token) do
    {posts, subreddits} =
      Enum.map(subreddits, &new_posts(&1, token))
      |> Enum.unzip()

    {List.flatten(posts), subreddits}
  end

  defp get_token(%Reddit{oauth: oauth} = state) do
    {token, oauth} = Reddit.Api.OAuth.get_token(oauth)
    {%{state | oauth: oauth}, token}
  end

  defp send_to_channel(%{"title" => caption, "url" => url}) do
    case send_captions() do
      true -> ChannelManager.send_to_source(url, caption)
      false -> ChannelManager.send_to_source(url, "")
    end
  end

  defp filter_posts(posts) do
    filter_posts(posts, [], [])
  end

  defp filter_posts([post | posts], send, keep) do
    {send, keep} =
      case filter?(post) do
        :send -> {[post | send], keep}
        :keep -> {send, [post | keep]}
        _ -> {send, keep}
      end

    filter_posts(posts, send, keep)
  end

  defp filter_posts([], send, keep) do
    {send, keep}
  end

  defp filter?(%{"post_hint" => type}) when type != "image", do: :discard
  defp filter?(%{"is_self" => true}), do: :discard

  defp filter?(%{"created_utc" => created, "ups" => upvotes}) do
    max_age = age_threshold()
    min_votes = vote_threshold()

    case {System.os_time(:second) - round(created), upvotes} do
      {_, upvotes} when upvotes >= min_votes -> :send
      {age, _} when age >= max_age -> :discard
      _ -> :keep
    end
  end

  defp new_posts({subreddit, before}, token) do
    response = Reddit.Api.new(token, subreddit, before)

    children =
      Enum.map(
        response["data"]["children"],
        fn child ->
          child["data"]
        end
      )

    image_posts =
      children
      |> Enum.map(&Map.take(&1, @keys_to_keep))

    new_before = List.first(children)["name"] || before
    {image_posts, {subreddit, new_before}}
  end
end
