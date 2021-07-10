defmodule ChannelManager.Api.Telegram do
  alias ChannelManager.Model.Post

  require Logger

  @bot :channel_manager

  use ExGram.Bot,
    name: @bot,
    setup_commands: true

  def bot(), do: @bot
  def me(), do: ExGram.get_me(bot: bot())

  middleware(ExGram.Middleware.IgnoreUsername)

  def send_post(post, target, true), do: send_post(post, target)
  def send_post(post, target, false), do: send_post(%Post{post | caption: ""}, target)

  def send_post(%Post{type: "link", url: url, caption: caption} = post, target) do
    message = caption <> "\n" <> url

    case ExGram.send_message(target, message, bot: bot()) do
      {:error, e} -> Logger.error("Failed to send post #{inspect(post)}: #{inspect(e)}")
      {:ok, _} -> nil
    end
  end

  def send_post(%Post{type: "image", url: url, caption: caption} = post, target) do
    case ExGram.send_photo(target, url, bot: bot(), caption: caption) do
      {:error, e} -> Logger.error("Failed to send post #{inspect(post)}: #{inspect(e)}")
      {:ok, _} -> nil
    end
  end

  def send_post(%Post{type: "rich:video"} = post, target), do: send_post(%{post | type: "link"}, target)
end
