defmodule ChannelManager.Api.Telegram do
  alias ChannelManager.Api.Telegram.Util
  alias ChannelManager.Api.Telegram.Messages

  require Logger

  @bot :channel_manager
  @default_opts %{"captions" => false, "vote_button" => false}

  use ExGram.Bot,
    name: @bot,
    setup_commands: true

  def bot(), do: @bot
  def me(), do: ExGram.get_me(bot: bot())

  middleware(ExGram.Middleware.IgnoreUsername)

  def handle({:callback_query, %{data: data, message: message} = query}, context) do
    {old_votes, _} = Integer.parse(data)
    new_votes = old_votes + 1
    id = Util.id(message)
    Messages.update_votes(id, new_votes)
    new_keyboard = Util.vote_keyboard(new_votes)
    edit(context, :markup, query, reply_markup: new_keyboard)
  end

  # TODO: Handle deletes and forward to Messages

  def send_post(post, target, opts) do
    opts = Map.merge(@default_opts, opts)

    case Util.build_params(post, opts) do
      nil -> nil
      params -> send_post(target, params)
    end
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
