defmodule ChannelManager.Forwarder.Target.Telegram do
  require Logger

  alias ChannelManager.Forwarder.Target
  @behaviour Target

  @impl Target
  def send(
        %Target{type: "telegram", target: target, options: options},
        %ChannelManager.Model.Post{type: "image", url: url, caption: caption} = post
      ) do
    caption =
      case Map.get(options, "captions", false) do
        true -> caption
        false -> ""
      end

    case ExGram.send_photo(target, url, bot: ChannelManager.bot(), caption: caption) do
      {:error, e} -> Logger.error("Failed to send post #{inspect(post)}: #{inspect(e)}")
      {:ok, _} -> nil
    end
  end

  def send(
        %Target{type: "telegram", target: target, options: options},
        %ChannelManager.Model.Post{type: "link", url: url, caption: caption} = post
      ) do
    caption =
      case Map.get(options, "captions", false) do
        true -> caption
        false -> ""
      end

    message = caption <> "\n" <> url

    case ExGram.send_message(target, message, bot: ChannelManager.bot()) do
      {:error, e} -> Logger.error("Failed to send post #{inspect(post)}: #{inspect(e)}")
      {:ok, _} -> nil
    end
  end
end
