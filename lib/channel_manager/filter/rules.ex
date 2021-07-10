defmodule ChannelManager.Filter.Rules do
  use TypedStruct

  typedstruct do
    field :approve, %{String.t() => String.t()}, default: %{}
    field :deny, %{String.t() => String.t()}, default: %{}
    field :filter, %{String.t() => String.t()}, default: %{}
  end
end
