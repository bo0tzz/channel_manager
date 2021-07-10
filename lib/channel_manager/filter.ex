defmodule ChannelManager.Filter do
  alias ChannelManager.Model.Post

  require Logger

  def filter_posts(
        %ChannelManager.Filter.Rules{approve: approve, deny: deny, filter: filter} = rules,
        posts
      ) do
    Logger.debug("Filtering #{length(posts)} posts with ruleset #{inspect(rules)}")

    [filtered, discarded] = filter_by(posts, filter)
    [approved, rest] = filter_by(filtered, approve)
    [denied, kept] = filter_by(rest, deny)

    Logger.info(
      "Filtered posts: discarded #{length(discarded)}, approved #{length(approved)}, denied #{length(denied)}, kept #{length(kept)}"
    )

    {approved, kept}
  end

  def filter_by(posts, rules), do: Enum.split_with(posts, &filter_with(&1, rules))
  def filter_with(post, rules), do: Enum.any?(rules, &matches(&1, post))

  def matches({"votes", rule_votes}, %Post{votes: post_votes}), do: post_votes >= rule_votes
  def matches({"type", rule_type}, %Post{type: post_type}), do: rule_type == post_type
  def matches({"text", rule_text}, %Post{caption: caption}), do: caption =~ ~r/#{rule_text}/i

  def matches({"age", rule_age}, %Post{timestamp: timestamp}),
    do: System.os_time(:second) - timestamp >= rule_age

  def matches({name, _}, _) do
    raise "Unknown rule: #{name}"
  end
end
