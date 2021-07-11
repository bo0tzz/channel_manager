defmodule ChannelManager.Forwarder.Server do
  use GenServer

  def start_link(arg) do
    GenServer.start_link(__MODULE__, arg)
  end

  def child_spec(%ChannelManager.Forwarder{name: name} = arg) do
    %{
      id: name,
      start: {__MODULE__, :start_link, [arg]}
    }
  end

  def child_spec(arg) do
    child_spec(ChannelManager.Forwarder.from_map(arg))
  end

  def init(%ChannelManager.Forwarder{} = forwarder) do
    state = ChannelManager.Forwarder.init(forwarder)
    schedule_next_job(0)
    {:ok, state}
  end

  def handle_info(:run, state) do
    state = ChannelManager.Forwarder.run(state)
    schedule_next_job(state.config.interval)
    {:noreply, state}
  end

  defp schedule_next_job(interval) do
    # Minutes to ms
    time = round(interval * 60 * 1000)
    # In 60 seconds
    Process.send_after(self(), :run, time)
  end
end
