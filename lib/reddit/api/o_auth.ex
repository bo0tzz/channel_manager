defmodule Reddit.Api.OAuth do
  defstruct [
    :client_id,
    :client_secret,
    :token,
    :expiry
  ]

  alias Reddit.Api.OAuth

  def get_token(%OAuth{token: nil} = state) do
    state = request_token(state)
    {state.token, state}
  end

  def get_token(%OAuth{expiry: exp} = state) do
    state = case System.os_time(:second) - exp do
      s_left when s_left < 10 -> request_token(state)
      _ -> state
    end

    {state.token, state}
  end

  defp request_token(state) do
    {:ok, response} = client(state)
    |> Tesla.post("/api/v1/access_token", %{grant_type: :client_credentials})

    body = Jason.decode!(response.body)

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
