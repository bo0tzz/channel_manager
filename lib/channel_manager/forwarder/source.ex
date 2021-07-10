defmodule ChannelManager.Forwarder.Source do
  use TypedStruct

  typedstruct enforce: true do
    field :type, String.t()
    field :source, String.t() | [String.t()]
    field :rules, ChannelManager.Filter.Rules.t()
  end

  @opaque state :: any()

  @callback init(ChannelManager.Forwarder.Source.t()) :: state()
  @callback get_posts(ChannelManager.Forwarder.Source.t(), state()) ::
              {[ChannelManager.Model.Post.t()], state()}

  def from_map(%{"type" => type, "source" => source, "rules" => rules}) do
    rules = ChannelManager.Filter.Rules.from_map(rules)

    %ChannelManager.Forwarder.Source{
      type: type,
      source: source,
      rules: rules
    }
  end

  def impl_for(%ChannelManager.Forwarder.Source{type: "rss"}),
    do: ChannelManager.Forwarder.Source.RSS

  def impl_for(%ChannelManager.Forwarder.Source{type: "reddit"}),
    do: ChannelManager.Forwarder.Source.Reddit
end
