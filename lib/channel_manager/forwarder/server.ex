defmodule ChannelManager.Forwarder.Server do
  use GenServer

  def start_link(arg) do
    GenServer.start_link(__MODULE__, arg)
  end

  def init(forwarder) do
    state = ChannelManager.Forwarder.init(forwarder)
    {:ok, state}
  end

  def handle_info(:run, state) do
    state = ChannelManager.Forwarder.run(state)
    schedule_next_job(state.config.interval)
    {:noreply, state}
  end

  defp schedule_next_job(interval) do
    # Minutes to ms
    time = interval * 60 * 1000
    # In 60 seconds
    Process.send_after(self(), :run, time)
  end
end
