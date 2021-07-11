defmodule ChannelManager.Api.Telegram.Util do
  require Logger

  import ExGram.Dsl.Keyboard
  alias ChannelManager.Model.Post

  def id(%{chat: %{id: chat_id}, message_id: message_id}), do: {chat_id, message_id}

  def build_params(%Post{type: "link", url: url} = post, opts) do
    text = get_caption(post, opts) <> "\n" <> url

    Map.merge(
      common_params(post, opts),
      %{
        text: text
      }
    )
  end

  def build_params(%Post{type: "rich:video"} = post, opts),
    do: build_params(%{post | type: "link"}, opts)

  def build_params(%Post{type: "image", url: url} = post, opts) do
    Map.merge(
      common_params(post, opts),
      %{
        photo: url,
        caption: get_caption(post, opts)
      }
    )
  end

  def build_params(%Post{type: type}, _) do
    Logger.warn("Post type #{type} is not supported")
    nil
  end

  defp common_params(%Post{}, %{"vote_button" => false}),
    do: %{
      bot: ChannelManager.Api.Telegram.bot()
    }

  defp common_params(%Post{votes: votes}, %{"vote_button" => true}),
    do: %{
      bot: ChannelManager.Api.Telegram.bot(),
      reply_markup: vote_keyboard(votes)
    }

  def vote_keyboard(votes) do
    button_text =
      case votes do
        0 -> "Vote"
        n -> "Votes: #{n}"
      end

    keyboard :inline do
      row do
        button(button_text, callback_data: votes)
      end
    end
  end

  defp get_caption(_, %{"captions" => false}), do: ""
  defp get_caption(%Post{caption: nil}, _), do: ""
  defp get_caption(%Post{caption: caption}, %{"captions" => true}), do: caption
end
