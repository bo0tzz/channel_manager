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

  def init(%ChannelManager.Forwarder{from: from, to: to} = config) do
    source_impl = ChannelManager.Forwarder.Source.impl_for(from)
    target_impl = ChannelManager.Forwarder.Target.impl_for(to)
    source_state = source_impl.init(from)

    %{
      config: config,
      source: %{
        impl: source_impl,
        config: from,
        state: source_state
      },
      target: %{
        impl: target_impl,
        config: to
      }
    }
  end

  def run(%{source: source, target: target} = state) do
    {posts, source} = call_source(source)
    call_target(target, posts)
    %{state | source: source}
  end

  defp call_source(
         %{
           impl: source_impl,
           config: source_config,
           state: source_state
         } = state
       ) do
    {posts, source_state} = source_impl.get_posts(source_config, source_state)
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
