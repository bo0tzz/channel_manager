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
  def handle_cast({:remove, id}, state) do
    state = Messages.remove(state, id)
    {:noreply, state, {:continue, :save}}
  end

  @impl true
  def handle_cast({:update_votes, id, votes}, state) do
    {:noreply, Messages.update_votes(state, id, votes), {:continue, :save}}
  end

  @impl true
  def handle_cast({:track_chat, chat_id}, state) do
    {:noreply, Messages.track_chat(state, chat_id)}
  end

  @impl true
  def handle_cast({:untrack_chat, chat_id}, state) do
    {:noreply, Messages.untrack_chat(state, chat_id)}
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
