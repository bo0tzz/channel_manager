defmodule Reddit.Server do
  use GenServer

  def start_link(_), do: GenServer.start_link(__MODULE__, nil, name: __MODULE__)

  @impl true
  def init(_) do
    state = Reddit.init()

    {
      :ok,
      state,
      {:continue, :initialize}
    }
  end

  @impl true
  def handle_continue(:initialize, state) do
    state = Reddit.discard_scan(state)

    {
      :noreply,
      state
    }
  end

  @impl true
  def handle_cast(:scan, state) do
    state = Reddit.do_scan(state)

    {
      :noreply,
      state
    }
  end
end
