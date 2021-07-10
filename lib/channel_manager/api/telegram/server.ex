defmodule ChannelManager.Api.Telegram.Server do
  alias ChannelManager.Api.Telegram.Messages

  use GenServer

  def start_link(arg), do: GenServer.start_link(__MODULE__, arg, name: __MODULE__)

  @impl true
  def init(arg) do
    state = Messages.init(arg)

    {
      :ok,
      state
    }
  end

  @impl true
  def handle_cast({:add, message}, state) do
    state = Messages.add(state, message)
    {:noreply, state, {:continue, :save}}
  end

  @impl true
  def handle_cast({:remove, message}, state) do
    state = Messages.remove(state, message)
    {:noreply, state, {:continue, :save}}
  end

  @impl true
  def handle_call({:get_all, chat_id}, _, state) do
    {:reply, Messages.get_all(state, chat_id), state}
  end

  @impl true
  def handle_continue(:save, state) do
    Messages.save(state)
    {:noreply, state}
  end
end
