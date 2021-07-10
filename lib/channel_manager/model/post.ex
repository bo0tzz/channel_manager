defmodule ChannelManager.Model.Post do
  use TypedStruct

  typedstruct enforce: true do
    field :id, String.t()
    field :caption, String.t()
    field :url, String.t()
    field :timestamp, integer()
    field :votes, integer(), enforce: false
    field :type, String.t()
  end

  def from_reddit(%{
        "title" => caption,
        "name" => id,
        "url" => url,
        "created_utc" => timestamp,
        "ups" => votes,
        "post_hint" => type
      }) do
    %ChannelManager.Model.Post{
      id: id,
      caption: caption,
      url: url,
      timestamp: round(timestamp),
      votes: votes,
      type: type
    }
  end

  def from_rss(%{
        :title => caption,
        :id => id,
        :url => url,
        :updated => updated
      }) do
    case DateTimeParser.parse_datetime(updated) do
      {:ok, datetime} ->
        %ChannelManager.Model.Post{
          id: id,
          caption: caption,
          url: url,
          timestamp: DateTime.to_unix(datetime),
          type: "link"
        }

      error ->
        error
    end
  end
end
