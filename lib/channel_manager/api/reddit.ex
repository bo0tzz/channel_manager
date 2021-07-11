defmodule ChannelManager.Api.Reddit do
  require Logger

  @api_root "https://oauth.reddit.com/"

  def new(subreddit) do
    new(subreddit, "")
  end

  def new(subreddit, before) do
    get("/r/" <> subreddit <> "/new?before=" <> before)
  end

  def bulk(names) do
    q =
      Enum.map(names, &String.trim/1)
      |> Enum.join(",")

    get("/by_id/" <> q)
  end

  defp get(url) do
    {:ok, response} = client() |> Tesla.get(url)

    {:ok, body} =
      case response do
        r when r.status in 200..299 -> Jason.decode(response.body)
        r -> {:error, r.status, r.body}
      end

    Enum.map(body["data"]["children"], fn child -> child["data"] end)
    |> Enum.map(&ChannelManager.Model.Post.from_reddit/1)
    |> Enum.reject(&match?(nil, &1))
  end

  defp client() do
    token = ChannelManager.Api.Reddit.OAuth.get_token()

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
