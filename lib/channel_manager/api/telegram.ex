defmodule ChannelManager.Api.Telegram do
  alias ChannelManager.Api.Telegram.Util

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
    params = Util.build_params(post, opts)
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
end
