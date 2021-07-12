defmodule ChannelManager.Api.Telegram do
  alias ChannelManager.Api.Telegram.Util
  alias ChannelManager.Api.Telegram.Messages

  require Logger

  @bot :channel_manager
  @default_opts %{"captions" => false, "vote_button" => false, "deny_button" => false}

  use ExGram.Bot,
    name: @bot,
    setup_commands: true

  def bot(), do: @bot
  def me(), do: ExGram.get_me(bot: bot())

  middleware(ExGram.Middleware.IgnoreUsername)

  def handle({:callback_query, %{data: "delete", message: message}}, _) do
    {chat_id, message_id} = id = Util.id(message)

    Messages.remove_with_callback(id, fn ->
      ExGram.delete_message(chat_id, message_id, bot: bot())
    end)
  end

  def handle(
        {:callback_query, %{data: data, message: %{reply_markup: keyboard} = message} = query},
        context
      ) do
    {old_votes, _} = Integer.parse(data)
    new_votes = old_votes + 1
    id = Util.id(message)
    Messages.update_votes(id, new_votes)
    new_keyboard = Util.update_keyboard_votes(keyboard, new_votes)
    reply_markup = struct(ExGram.Model.InlineKeyboardMarkup, new_keyboard)
    edit(context, :markup, query, reply_markup: reply_markup)
  end

  def send_post(post, target, opts) do
    opts = Map.merge(@default_opts, opts)

    case Util.build_params(post, opts) do
      nil -> nil
      params -> send_post(target, params)
    end
  end

  defp send_post(target, %{photo: photo} = params) do
    case ExGram.send_photo(target, photo, Keyword.new(params)) do
      {:error, e} ->
        Logger.error("Failed to send post #{inspect(params)}: #{inspect(e)}")
        {:error}

      ok ->
        ok
    end
  end

  defp send_post(target, %{text: text} = params) do
    case ExGram.send_message(target, text, Keyword.new(params)) do
      {:error, e} ->
        Logger.error("Failed to send post #{inspect(params)}: #{inspect(e)}")
        {:error}

      ok ->
        ok
    end
  end
end
