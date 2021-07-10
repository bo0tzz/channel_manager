defmodule ChannelManager.Api.Reddit do
  require Logger

  @api_root "https://oauth.reddit.com/"

  def new(token, subreddit) do
    new(token, subreddit, "")
  end

  def new(token, subreddit, before) do
    get(token, "/r/" <> subreddit <> "/new?before=" <> before)
  end

  def bulk(names, token) do
    q =
      Enum.map(names, &String.trim/1)
      |> Enum.join(",")

    get(token, "/by_id/" <> q)
  end

  defp get(token, url) do
    {:ok, response} = client(token) |> Tesla.get(url)
    body = Jason.decode!(response.body)

    Enum.map(body["data"]["children"], fn child -> child["data"] end)
    |> Enum.map(&ChannelManager.Model.Post.from_reddit/1)
    |> Enum.reject(&match?(nil, &1))
  end

  defp client(token) do
    Tesla.client([
      {Tesla.Middleware.BaseUrl, @api_root},
      {Tesla.Middleware.Headers,
       [
         {"Authorization", "Bearer " <> token},
         {"User-Agent", "bo0tzz:telegram-channel-mirror:v0.1.0"}
       ]}
    ])
  end
end