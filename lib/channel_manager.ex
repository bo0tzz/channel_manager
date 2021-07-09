defmodule ChannelManager do
  require Logger

  @bot :channel_manager
  @approval_texts [
    "ok",
    "/ok",
    "approve",
    "approved",
    "👍",
    "good",
    "yes"
  ]

  use ExGram.Bot,
    name: @bot,
    setup_commands: true

  def bot(), do: @bot
  def me(), do: ExGram.get_me(bot: bot())

  def source_channel(),
    do: Integer.parse(Application.fetch_env!(:channel_manager, :source_channel)) |> elem(0)

  def target_channel(),
    do: Integer.parse(Application.fetch_env!(:channel_manager, :target_channel)) |> elem(0)

  def delete_approved(), do: Application.fetch_env!(:channel_manager, :delete_approved) == "true"

  command("ok", description: "Reply to a post with this command to approve it")

  middleware(ExGram.Middleware.IgnoreUsername)

  def handle(
        {:update,
         %{channel_post: %{chat: %{id: from}, reply_to_message: reply_to, text: text} = post}},
        context
      ) do
    Logger.debug("Handling possible approve message from #{from}")

    if from == source_channel() and String.downcase(text) in @approval_texts do
      Logger.debug("Message approved!")
      approve(reply_to, context, post)
    end
  end

  def approve(%{caption: caption, photo: photo} = message, context, approval_msg) do
    Logger.debug("Forwarding message to target channel #{target_channel()}")
    send_to_target(List.first(photo).file_id, caption)

    if delete_approved() do
      context
      |> delete(message)
      |> delete(approval_msg)
    end
  end

  def approve(%{photo: _} = message, context, approval_msg) do
    Logger.debug("Target message did not have caption")

    Map.put(message, :caption, "")
    |> approve(context, approval_msg)
  end

  def send_to_target(image, caption), do: send_to(target_channel(), image, caption)
  def send_to_source(image, caption), do: send_to(source_channel(), image, caption)

  def send_to(target, image, caption),
    do: {:ok, _} = ExGram.send_photo(target, image, bot: bot(), caption: caption)
end
