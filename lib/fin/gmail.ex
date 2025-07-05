defmodule Fin.Gmail do
  alias Tesla
  alias Jason

  @gmail_api_base_url "https://www.googleapis.com/gmail/v1/users/me"

  def list_messages(access_token, user_id, opts \\ []) do
    client = client(access_token)
    query_params = Keyword.put(opts, :userId, user_id)
    query_params = Keyword.put_new(query_params, :maxResults, 10) # Default to 10 messages

    case Tesla.get(client, "#{@gmail_api_base_url}/messages", query: query_params) do
      {:ok, %Tesla.Env{status: 200, body: body}} ->
        case body do
          %{"messages" => messages} ->
            {:ok, messages}
          _ ->
            {:error, :invalid_response_format}
        end
      {:ok, %Tesla.Env{status: status, body: body}} ->
        {:error, {:http_error, status, body}}
      {:error, reason} ->
        {:error, reason}
    end
  end

  def get_message(access_token, message_id, opts \\ []) do
    client = client(access_token)
    query_params = Keyword.put(opts, :format, "full") # Request full message details

    case Tesla.get(client, "#{@gmail_api_base_url}/messages/#{message_id}", query: query_params) do
      {:ok, %Tesla.Env{status: 200, body: body}} ->
        case body do
          message when is_map(message) ->
            {:ok, message}
          _ ->
            {:error, :invalid_response_format}
        end
      {:ok, %Tesla.Env{status: status, body: body}} ->
        {:error, {:http_error, status, body}}
      {:error, reason} ->
        {:error, reason}
    end
  end

  defp client(access_token) do
    Tesla.client([
      {Tesla.Middleware.Headers, [{"Authorization", "Bearer #{access_token}"}]},
      Tesla.Middleware.JSON
    ])
  end
end
