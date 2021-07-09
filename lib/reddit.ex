defmodule Reddit do
  require Logger

  defstruct [
    :subreddits
  ]

  @keys_to_keep ["title", "name", "url"]

  defp send_captions(), do: Application.fetch_env!(:channel_manager, :send_captions)

  def init() do
    subreddits =
      Application.fetch_env!(:channel_manager, :subreddits)
      |> Enum.map(&{&1, ""})

    %Reddit{subreddits: subreddits}
  end

  def trigger_scan(), do: GenServer.cast(Reddit.Server, :scan)

  def discard_scan(%Reddit{subreddits: subreddits} = state) do
    {p, subreddits} = get_posts(subreddits)
    Logger.debug("Discarding #{length(p)} posts")

    %{state | subreddits: subreddits}
  end

  def do_scan(%Reddit{subreddits: subreddits} = state) do
    {posts, subreddits} = get_posts(subreddits) |> IO.inspect()
    Logger.info("Got #{length(posts)} new posts")
    Enum.each(posts, &send_to_channel/1)
    %{state | subreddits: subreddits}
  end

  defp get_posts(subreddits) do
    {posts, subreddits} =
      Enum.map(subreddits, &new_posts/1)
      |> Enum.unzip()

    {List.flatten(posts), subreddits}
  end

  defp send_to_channel(%{"title" => caption, "url" => url}) do
    case send_captions() do
      true -> ChannelManager.send_to_source(url, caption)
      false -> ChannelManager.send_to_source(url, "")
    end
  end

  defp new_posts({subreddit, before}) do
    response = Reddit.Api.new(subreddit, before)

    children =
      Enum.map(
        response["data"]["children"],
        fn child ->
          child["data"]
        end
      )

    image_posts =
      children
      |> Enum.filter(fn child -> child["post_hint"] == "image" end)
      |> Enum.map(&Map.take(&1, @keys_to_keep))

    new_before = List.first(children)["name"] || before
    {image_posts, {subreddit, new_before}}
  end
end
