defmodule Fin.LLM do
  alias Tesla
  alias Jason

  @gemini_api_url "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent"
  @gemini_embedding_url "https://generativelanguage.googleapis.com/v1beta/models/text-embedding-004:embedContent"

  def generate_content(prompt_text) do
    api_key = System.fetch_env!("GOOGLE_AI_API_KEY")

    client =
      Tesla.client([
        {Tesla.Middleware.Headers,
         [{"X-goog-api-key", api_key}, {"Content-Type", "application/json"}]},
        Tesla.Middleware.JSON
      ])

    body = %{
      contents: [
        %{
          parts: [
            %{text: prompt_text}
          ]
        }
      ]
    }

    with {:ok,
          %Tesla.Env{
            status: 200,
            body: %{"candidates" => [%{"content" => %{"parts" => [%{"text" => response}]}}]}
          }} <-
           Tesla.post(client, @gemini_api_url, body) do
      {:ok, response}
    end
  end

  @doc """
  Generate vector embedding for text using Google's text-embedding-004 model
  Returns a list of float values representing the text as a vector
  """
  def generate_embedding(text) do
    api_key = System.fetch_env!("GOOGLE_AI_API_KEY")

    client =
      Tesla.client([
        {Tesla.Middleware.Headers,
         [{"X-goog-api-key", api_key}, {"Content-Type", "application/json"}]},
        Tesla.Middleware.JSON
      ])

    body = %{
      content: %{
        parts: [%{text: text}]
      }
    }

    with {:ok,
          %Tesla.Env{
            status: 200,
            body: %{"embedding" => %{"values" => embedding_values}}
          }} <-
           Tesla.post(client, @gemini_embedding_url, body) do
      {:ok, embedding_values}
    else
      {:ok, %Tesla.Env{status: status, body: body}} ->
        {:error, "API request failed with status #{status}: #{inspect(body)}"}
      
      {:error, reason} ->
        {:error, "Network error: #{inspect(reason)}"}
    end
  end
end
