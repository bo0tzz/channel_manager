defmodule ChannelManager.Api.Telegram.Messages do
  require Logger

  alias ChannelManager.Api.Telegram.Messages
  alias ChannelManager.Api.Telegram.Server

  defstruct [
    :storage_path,
    :messages,
    :tracked_chats
  ]

  def add(%ExGram.Model.Message{} = message),
    do: add(ChannelManager.Model.Post.from_telegram(message))

  def add(message), do: GenServer.cast(Server, {:add, message})
  def remove(%ChannelManager.Model.Post{id: id}), do: remove(id)
  def remove(id), do: GenServer.cast(Server, {:remove, id})
  def get_all(chat_id), do: GenServer.call(Server, {:get_all, chat_id})
  def update_votes(id, votes), do: GenServer.cast(Server, {:update_votes, id, votes})
  def track_chat(chat_id), do: GenServer.cast(Server, {:track_chat, chat_id})
  def untrack_chat(chat_id), do: GenServer.cast(Server, {:untrack_chat, chat_id})

  def init(%{"storage_path" => path}) do
    %Messages{
      storage_path: path,
      messages: load(path),
      tracked_chats: MapSet.new()
    }
  end

  def add(%Messages{messages: messages, tracked_chats: tracked_chats} = state, message) do
    case message.id in tracked_chats do
      false -> state
      true -> %{state | messages: Map.put(messages, message.id, message)}
    end
  end

  def remove(%Messages{messages: messages} = state, id),
    do: %{state | messages: Map.drop(messages, id)}

  def get_all(%Messages{messages: messages}, chat_id) do
    :maps.filter(&match?({{^chat_id, _}, _}, {&1, &2}), messages)
    |> Enum.map(fn {_, msg} -> msg end)
  end

  def update_votes(%Messages{messages: messages} = state, id, votes) do
    messages =
      case Map.has_key?(messages, id) do
        false ->
          messages

        true ->
          Map.update!(messages, id, fn post -> %ChannelManager.Model.Post{post | votes: votes} end)
      end

    %{state | messages: messages}
  end

  def track_chat(%Messages{tracked_chats: tracked_chats} = state, id),
    do: %{state | tracked_chats: MapSet.put(tracked_chats, id)}

  def untrack_chat(%Messages{tracked_chats: tracked_chats} = state, id),
    do: %{state | tracked_chats: MapSet.delete(tracked_chats, id)}

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
