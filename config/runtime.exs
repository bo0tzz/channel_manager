import Config

if Config.config_env() == :dev do
  DotenvParser.load_file(".env")
end

config :channel_manager,
  bot_token: System.fetch_env!("BOT_TOKEN"),
  reddit_client_id: System.fetch_env!("REDDIT_CLIENT_ID"),
  reddit_client_secret: System.fetch_env!("REDDIT_CLIENT_SECRET"),
  source_channel: Integer.parse(System.fetch_env!("SOURCE_CHANNEL")) |> elem(0),
  target_channel: Integer.parse(System.fetch_env!("TARGET_CHANNEL")) |> elem(0),
  subreddits:
    System.fetch_env!("SUBREDDITS")
    |> String.split()
    |> Enum.map(&String.replace(&1, ~r"^/?r/", "")),
  delete_approved: System.get_env("DELETE_APPROVED", "false") == "true",
  send_captions: System.get_env("SEND_CAPTIONS", "false") == "true",
  reddit_vote_threshold: Integer.parse(System.get_env("REDDIT_VOTE_THRESHOLD", "10")) |> elem(0),
  reddit_age_threshold: Integer.parse(System.get_env("REDDIT_AGE_THRESHOLD", "86400")) |> elem(0)

crontab = System.get_env("CRON_SCHEDULE", "*/10 * * * *")

config :channel_manager, ChannelManager.Scheduler,
       jobs: [
         {crontab, {Reddit, :trigger_scan, []}}
       ]