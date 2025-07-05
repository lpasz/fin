defmodule Fin.LLM do
  alias Tesla
  alias Jason

  @gemini_api_url "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent"

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
end
