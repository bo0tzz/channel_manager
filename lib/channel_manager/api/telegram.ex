defmodule ChannelManager.Api.Telegram do
  alias ChannelManager.Model.Post

  require Logger

  @bot :channel_manager
  @default_opts %{"captions" => false, "vote_button" => false}

  use ExGram.Bot,
    name: @bot,
    setup_commands: true

  def bot(), do: @bot
  def me(), do: ExGram.get_me(bot: bot())

  middleware(ExGram.Middleware.IgnoreUsername)

  def send_post(post, target, opts) do
    opts = Map.merge(@default_opts, opts)
    params = build_params(post, opts)
    send_post(target, params)
  end

  defp send_post(target, %{photo: photo} = params) do
    case ExGram.send_photo(target, photo, Keyword.new(params)) do
      {:error, e} -> Logger.error("Failed to send post #{inspect(params)}: #{inspect(e)}")
      {:ok, result} -> result
    end
  end

  defp send_post(target, %{text: text} = params) do
    case ExGram.send_message(target, text, Keyword.new(params)) do
      {:error, e} -> Logger.error("Failed to send post #{inspect(params)}: #{inspect(e)}")
      {:ok, result} -> result
    end
  end

  defp build_params(%Post{type: "link", url: url} = post, opts) do
    text = get_caption(post, opts) <> "\n" <> url

    Map.merge(
      common_params(post, opts),
      %{
        text: text
      }
    )
  end

  defp build_params(%Post{type: "rich:video"} = post, opts),
    do: build_params(%{post | type: "link"}, opts)

  defp build_params(%Post{type: "image", url: url} = post, opts) do
    Map.merge(
      common_params(post, opts),
      %{
        photo: url,
        caption: get_caption(post, opts)
      }
    )
  end

  defp common_params(%Post{}, _opts) do
    %{
      bot: bot()
      # TODO: vote button
    }
  end

  defp get_caption(_, %{"captions" => false}), do: ""
  defp get_caption(%Post{caption: caption}, %{"captions" => true}), do: caption
end
