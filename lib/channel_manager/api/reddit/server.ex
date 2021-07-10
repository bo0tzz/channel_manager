defmodule ChannelManager.Api.Reddit.Server do
  alias ChannelManager.Api.Reddit.OAuth

  use GenServer

  def start_link(arg), do: GenServer.start_link(__MODULE__, arg, name: __MODULE__)

  @impl true
  def init(arg) do
    state = OAuth.from_map(arg)

    {
      :ok,
      state
    }
  end

  @impl true
  def handle_call(:token, _, state) do
    {token, state} = OAuth.get_token(state)
    {:reply, token, state}
  end
end
