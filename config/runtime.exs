import Config

default_config_path = Path.join(File.cwd!(), "config.yaml")
config_path = System.get_env("CONFIG_PATH", default_config_path)

yaml = YamlElixir.read_from_file!(config_path)
IO.inspect(yaml)

config :channel_manager,
  bot_token: yaml["telegram"]["token"],
  reddit_client_id: yaml["reddit"]["client_id"],
  reddit_client_secret: yaml["reddit"]["client_secret"],
  source_channel: yaml["telegram"]["source_channel"],
  target_channel: yaml["telegram"]["target_channel"],
  subreddits:
    yaml["reddit"]["subreddits"]
    |> Enum.map(&String.replace(&1, ~r"^/?r/", "")),
  delete_approved: yaml["telegram"]["delete_approved"],
  send_captions: yaml["telegram"]["send_captions"],
  reddit_vote_threshold: yaml["reddit"]["vote_threshold"],
  reddit_age_threshold: yaml["reddit"]["age_threshold"]

crontab = yaml["scheduler"]["crontab"]

config :channel_manager, ChannelManager.Scheduler,
       jobs: [
         {crontab, {Reddit, :trigger_scan, []}}
       ]