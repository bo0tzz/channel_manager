defmodule ChannelManager.Forwarder.Target do
  use TypedStruct

  typedstruct enforce: true do
    field :type, String.t()
    field :target, String.t()
    field :options, %{String.t() => String.t()}, default: %{}
  end

  @callback send(ChannelManager.Forwarder.Target.t(), ChannelManager.Model.Post.t()) :: none()

  def from_map(%{"type" => type, "target" => target} = map) do
    options = Map.get(map, "options", %{})

    %ChannelManager.Forwarder.Target{
      type: type,
      target: target,
      options: options
    }
  end

  def impl_for(%ChannelManager.Forwarder.Target{type: "telegram"}),
    do: ChannelManager.Forwarder.Target.Telegram
end
