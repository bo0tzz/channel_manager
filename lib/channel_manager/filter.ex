defmodule ChannelManager.Filter do
  alias ChannelManager.Model.Post

  require Logger

  def filter_posts(
        %ChannelManager.Filter.Rules{approve: approve, deny: deny, filter: filter} = rules,
        posts
      ) do
    Logger.debug("Filtering #{length(posts)} posts with ruleset #{inspect(rules)}")

    {filtered, discarded} = case filter do
      %{} -> {posts, []}
      f -> filter_by(posts, f)
    end

    {denied, rest} = filter_by(filtered, deny)
    {approved, kept} = filter_by(rest, approve)

    Logger.info(
      "Filtered posts: discarded #{length(discarded)}, approved #{length(approved)}, denied #{length(denied)}, kept #{length(kept)}"
    )

    {approved, kept}
  end

  defp filter_by(posts, rules), do: Enum.split_with(posts, &filter_with(&1, rules))
  defp filter_with(post, rules), do: Enum.any?(rules, &matches(&1, post))

  defp matches({"votes", rule_votes}, %Post{votes: post_votes}), do: post_votes >= rule_votes
  defp matches({"type", rule_type}, %Post{type: post_type}), do: rule_type == post_type
  defp matches({"text", rule_text}, %Post{caption: caption}), do: caption =~ ~r/#{rule_text}/i

  defp matches({"age", rule_age}, %Post{timestamp: timestamp}),
    do: System.os_time(:second) - timestamp >= rule_age

  defp matches({name, _}, _) do
    raise "Unknown rule: #{name}"
  end
end
