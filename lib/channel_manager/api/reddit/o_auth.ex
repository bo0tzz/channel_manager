defmodule ChannelManager.Api.Reddit.OAuth do
  require Logger

  defstruct [
    :client_id,
    :client_secret,
    :token,
    :expiry
  ]

  alias ChannelManager.Api.Reddit.OAuth

  def get_token() do
    GenServer.call(ChannelManager.Api.Reddit.Server, :token)
  end

  def from_map(%{"client_id" => client_id, "client_secret" => client_secret}) do
    %OAuth{client_id: client_id, client_secret: client_secret}
  end

  def get_token(%OAuth{token: nil} = state) do
    state = request_token(state)
    {state.token, state}
  end

  def get_token(%OAuth{expiry: exp} = state) do
    state =
      case exp - System.os_time(:second) do
        s_left when s_left < 60 -> request_token(state)
        _ -> state
      end

    {state.token, state}
  end

  def request_token(state) do
    client(state)
    |> Tesla.post("/api/v1/access_token", %{grant_type: :client_credentials})
    |> case do
      {:ok, response} ->
        parse_response(response, state)

      {:error, err} ->
        Logger.warn("Reddit api error: #{inspect(err)}")
        nil
    end
  end

  defp parse_response(%{status: status, body: body}, state) when status in 200..299 do
    {:ok, data} = Jason.decode(body)

    token = data["access_token"]
    expires_in = data["expires_in"]
    expiry = System.os_time(:second) + expires_in

    %{state | token: token, expiry: expiry}
  end

  defp parse_response(%{status: status, body: body}, state) do
    Logger.warn("Could not request OAuth token. Reddit returned error status #{status}")
    Logger.debug("Reddit response body: #{body}")
    %{state | token: "", expiry: 0}
  end

  defp client(%OAuth{client_id: id, client_secret: secret}) do
    Tesla.client([
      {Tesla.Middleware.BaseUrl, "https://www.reddit.com"},
      Tesla.Middleware.FormUrlencoded,
      {Tesla.Middleware.BasicAuth, %{username: id, password: secret}}
    ])
  end
end
