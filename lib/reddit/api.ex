defmodule Reddit.Api do
  require Logger

  @api_root "https://www.reddit.com/r/"
  @new_posts "/new.json"
  @before "?before="

  def new(subreddit) do
    new(subreddit, "")
  end

  def new(subreddit, before) do
    get(@api_root <> subreddit <> @new_posts <> @before <> before)
  end

  defp get(url) do
    {:ok, response} = Tesla.get(url)
    Jason.decode!(response.body)
  end
end
