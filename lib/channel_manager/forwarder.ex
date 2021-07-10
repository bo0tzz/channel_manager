defmodule ChannelManager.Forwarder do
  use TypedStruct

  typedstruct enforce: true do
    field :name, String.t()
    field :schedule, String.t()
    field :from, ChannelManager.Forwarder.Source.t()
    field :to, ChannelManager.Forwarder.Target.t()
  end

  def from_map(%{"name" => name, "schedule" => schedule, "from" => from, "to" => to}) do
    from = ChannelManager.Forwarder.Source.from_map(from)
    to = ChannelManager.Forwarder.Target.from_map(to)

    %ChannelManager.Forwarder{
      name: name,
      schedule: schedule,
      from: from,
      to: to
    }
  end
end
