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
    client()
    |> Tesla.get(url)
    |> case do
      {:ok, response} ->
        parse_response(response)

      {:error, err} ->
        Logger.warn("Reddit api error: #{inspect(err)}")
        []
    end
  end

  defp parse_response(%{status: status, body: body}) when status in 200..299 do
    {:ok, data} = Jason.decode(body)

    Enum.map(data["data"]["children"], fn child -> child["data"] end)
    |> Enum.map(&ChannelManager.Model.Post.from_reddit/1)
    |> Enum.reject(&match?(nil, &1))
  end

  defp parse_response(%{status: status, body: body}) do
    Logger.warn("Reddit returned error status #{status}. Skipping this run")
    Logger.debug("Reddit response body: #{body}")
    []
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
