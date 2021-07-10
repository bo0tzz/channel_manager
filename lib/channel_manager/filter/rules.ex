defmodule ChannelManager.Filter.Rules do
  use TypedStruct

  typedstruct enforce: true do
    field :approve, %{String.t() => String.t()}
    field :deny, %{String.t() => String.t()}
    field :filter, %{String.t() => String.t()}
  end

  def from_map(rules) do
    approve = Map.fetch!(rules, "approve")
    filter = Map.get(rules, "filter", %{})
    deny = Map.get(rules, "deny", %{})

    %ChannelManager.Filter.Rules{
      approve: approve,
      filter: filter,
      deny: deny
    }
  end
end
