defmodule ChannelManager.Api.Telegram.Messages do
  require Logger

  alias ChannelManager.Api.Telegram.Messages
  alias ChannelManager.Api.Telegram.Server

  defstruct [
    :storage_path,
    :messages
  ]

  def add(message), do: GenServer.cast(Server, {:add, message})
  def remove(message), do: GenServer.cast(Server, {:remove, message})
  def get_all(chat_id), do: GenServer.call(Server, {:get_all, chat_id})

  def init(%{storage_path: path}) do
    %Messages{
      storage_path: path,
      messages: load(path)
    }
  end

  def add(state, %ExGram.Model.Message{} = message), do: add(state, Map.from_struct(message))

  def add(%Messages{messages: messages} = state, message) do
    message = :maps.filter(fn _, v -> v != nil end, message)
    messages = Map.put(messages, key(message), message)
    # TODO: Call registry by chat ID, notify source listeners

    %{state | messages: messages}
  end

  def remove(%Messages{messages: messages} = state, message),
    do: %{state | messages: Map.drop(messages, key(message))}

  def get_all(%Messages{messages: messages}, chat_id) do
    :maps.filter(&match?({^chat_id, _}, &1), messages)
  end

  defp key(%{message: %{message_id: message_id, chat: %{id: chat_id}}}), do: {chat_id, message_id}

  def save(%Messages{storage_path: path, messages: messages} = state) do
    Logger.debug("Saving state: #{inspect(state)}")
    data = :erlang.term_to_binary(messages)

    case File.write(path, data) do
      :ok ->
        Logger.info("Saved telegram messages database")
        :ok

      {:error, reason} ->
        Logger.error(
          "Failed to write telegram messages database to #{path}: #{:file.format_error(reason)}"
        )
    end
  end

  defp load(path) do
    case File.read(path) do
      {:ok, bin} ->
        Logger.info("Loading telegram messages database from path #{path}")
        :erlang.binary_to_term(bin)

      {:error, reason} ->
        Logger.warn(
          "Could not read telegram messages database at path #{path}: #{:file.format_error(reason)}"
        )

        Logger.info("Initializing telegram messages database")
        %{}
    end
  end
end
