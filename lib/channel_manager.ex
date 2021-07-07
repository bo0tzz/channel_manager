defmodule ChannelManager do
  @bot :channel_manager

  use ExGram.Bot,
    name: @bot,
    setup_commands: true

  def bot(), do: @bot
  def me(), do: ExGram.get_me(bot: bot())

  command("start", description: "Get started")

  middleware(ExGram.Middleware.IgnoreUsername)

  def handle({:command, :start, _}, context), do: answer(context, "Hello world!")
end
