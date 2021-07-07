import Config

if Config.config_env() == :dev do
  DotenvParser.load_file(".env")
end

config :channel_manager,
  bot_token: System.fetch_env!("BOT_TOKEN")