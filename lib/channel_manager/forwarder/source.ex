defmodule ChannelManager.Forwarder.Source do
  use TypedStruct

  typedstruct enforce: true do
    field :type, String.t()
    field :source, String.t() | [String.t()]
    field :rules, ChannelManager.Filter.Rules.t()
  end

  def from_map(%{"type" => type, "source" => source, "rules" => rules}) do
    rules = ChannelManager.Filter.Rules.from_map(rules)

    %ChannelManager.Forwarder.Source{
      type: type,
      source: source,
      rules: rules
    }
  end
end
