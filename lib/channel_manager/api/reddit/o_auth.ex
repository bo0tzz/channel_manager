defmodule ChannelManager.Api.Reddit.OAuth do
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
      case System.os_time(:second) - exp do
        s_left when s_left < 60 -> request_token(state)
        _ -> state
      end

    {state.token, state}
  end

  def request_token(state) do
    {:ok, response} =
      client(state)
      |> Tesla.post("/api/v1/access_token", %{grant_type: :client_credentials})

    {:ok, body} =
      case response do
        r when r.status in 200..299 -> Jason.decode(response.body)
        r -> {:error, r.status, r.body}
      end

    token = body["access_token"]
    expires_in = body["expires_in"]
    expiry = System.os_time(:second) + expires_in

    %{state | token: token, expiry: expiry}
  end

  defp client(%OAuth{client_id: id, client_secret: secret}) do
    Tesla.client([
      {Tesla.Middleware.BaseUrl, "https://www.reddit.com"},
      Tesla.Middleware.FormUrlencoded,
      {Tesla.Middleware.BasicAuth, %{username: id, password: secret}}
    ])
  end
end
