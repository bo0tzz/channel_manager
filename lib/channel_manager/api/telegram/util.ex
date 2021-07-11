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

  defp common_params(%Post{} = post, opts) do
    params = %{
      bot: ChannelManager.Api.Telegram.bot()
    }

    keyboard = build_keyboard(post, opts)

    case has_content(keyboard) do
      false -> params
      true -> Map.put(params, :reply_markup, keyboard)
    end
  end

  def build_keyboard(_, %{"vote_button" => false, "deny_button" => false}), do: nil

  def build_keyboard(%Post{votes: votes}, %{"vote_button" => true, "deny_button" => false}) do
    keyboard :inline do
      row do
        button vote_button_text(votes), callback_data: votes
      end
    end
  end

  def build_keyboard(_, %{"vote_button" => false, "deny_button" => true}) do
    keyboard :inline do
      row do
        button "Remove post", callback_data: "delete"
      end
    end
  end

  def build_keyboard(%Post{votes: votes}, %{"vote_button" => true, "deny_button" => true}) do
    keyboard :inline do
      row do
        button vote_button_text(votes), callback_data: votes
      end
      row do
        button "Remove post", callback_data: "delete"
      end
    end
  end

  defp vote_button_text(0), do: "Vote"
  defp vote_button_text(votes), do: "Votes: #{votes}"

  def update_keyboard_votes(keyboard, votes), do: update_in(keyboard[:inline_keyboard], &update_keyboard_rows(&1, votes))

  def update_keyboard_rows(rows, votes), do: Enum.map(rows, &update_keyboard_row(&1, votes))
  def update_keyboard_row(row, votes), do: Enum.map(row, &update_keyboard_button(&1, votes))

  def update_keyboard_button(%{text: "Vote" <> _} = button, votes),
    do: %{button | text: "Votes: #{votes}", callback_data: votes}

  def update_keyboard_button(button, _), do: button

  defp has_content(%ExGram.Model.InlineKeyboardMarkup{inline_keyboard: []}), do: false
  defp has_content(%ExGram.Model.InlineKeyboardMarkup{inline_keyboard: [[]]}), do: false
  defp has_content(nil), do: false
  defp has_content(_), do: true

  defp get_caption(_, %{"captions" => false}), do: ""
  defp get_caption(%Post{caption: nil}, _), do: ""
  defp get_caption(%Post{caption: caption}, %{"captions" => true}), do: caption
end
