import Config

default_config_path = Path.join(File.cwd!(), "config.yaml")
config_path = System.get_env("CONFIG_PATH", default_config_path)

yaml = YamlElixir.read_from_file!(config_path)

config :channel_manager,
  config: yaml,
  reddit_client_id: yaml["reddit"]["client_id"],
  reddit_client_secret: yaml["reddit"]["client_secret"]
