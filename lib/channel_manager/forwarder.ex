defmodule ChannelManager.Forwarder do
  require Logger

  use TypedStruct

  typedstruct enforce: true do
    field :name, String.t()
    field :interval, integer()
    field :from, ChannelManager.Forwarder.Source.t()
    field :to, ChannelManager.Forwarder.Target.t()
  end

  def from_map(%{"name" => name, "interval" => interval, "from" => from, "to" => to}) do
    from = ChannelManager.Forwarder.Source.from_map(from)
    to = ChannelManager.Forwarder.Target.from_map(to)

    %ChannelManager.Forwarder{
      name: name,
      interval: interval,
      from: from,
      to: to
    }
  end

  def init(%ChannelManager.Forwarder{from: from, to: to, name: name} = config) do
    source_impl = ChannelManager.Forwarder.Source.impl_for(from)
    target_impl = ChannelManager.Forwarder.Target.impl_for(to)
    source_state = source_impl.init(from)

    Logger.info("Initialized forwarder #{name}")

    %{
      config: config,
      source: %{
        impl: source_impl,
        state: source_state
      },
      target: %{
        impl: target_impl,
        config: to
      }
    }
  end

  def run(%{source: source, target: target, config: %{name: name}} = state) do
    Logger.debug("Running forwarder #{name}")
    {posts, source} = call_source(source)
    call_target(target, posts)
    %{state | source: source}
  end

  defp call_source(
         %{
           impl: source_impl,
           state: source_state
         } = state
       ) do
    {posts, source_state} = source_impl.get_posts(source_state)
    {posts, %{state | state: source_state}}
  end

  defp call_target(
         %{
           impl: target_impl,
           config: target_config
         },
         posts
       ) do
    Enum.each(posts, &target_impl.send(target_config, &1))
  end
end
