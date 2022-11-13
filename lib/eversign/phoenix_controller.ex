defmodule Eversign.PhoenixController do
  @moduledoc """
  Implements a PhoenixController that can be easily wired up and used.

  ## Examples

  ```elixir
  defmodule YourAppWeb.EversignController do
    use Eversign.PhoenixController

    def handle_document_change(document_hash, action, _time, _details) do
      Documents.get_by!(eversign_document_hash: document_hash)
      |> Documents.update_document(%{status: action})
    end

    def handle_document_complete(document_hash, pdf, _details) do
      Documents.get_by!(eversign_document_hash: document_hash)
      |> Documents.update_document(%{data: pdf, status: status})
    end
  end
  ```

  Put the following lines into your `router.ex` and configure the WebHook in the eversign Application Settings.

  ```elixir
    post "/callbacks/eversign", YourAppWeb.EversignController, :webhook
  ```

  """

  @doc """
  Triggers when a Eversign document changed.
  """
  @callback handle_document_change(String.t(), String.t(), String.t(), map()) :: any()

  @doc """
  Triggers when a Eversign document has been completed/signed by all signers.
  """
  @callback handle_document_complete(String.t(), binary(), map()) :: any()

  defmacro __using__(_) do
    quote do
      @moduledoc "Implements a PhoenixController with callbacks for Eversign."
      @behaviour Eversign.PhoenixController
      require Logger
      use Phoenix.Controller
      alias Plug.Conn

      @doc "default webhook that should match."
      @spec webhook(Conn.t(), map()) :: Conn.t()
      def webhook(conn, params) do
        parse_document(params)
        Conn.send_resp(conn, 200, "")
      end

      # parsing valid document state changes
      defp parse_document(
             %{
               "event_type" => "document_completed",
               "event_time" => time,
               "event_hash" => hash,
               "meta" =>
                 %{
                   "related_document_hash" => document_hash,
                   "related_user_id" => _user_id,
                   "related_business_id" => _business_id,
                   "related_app_id" => _app_id
                 } = _meta
             } = data
           ) do
        pdf = download_data(document_hash)
        handle_document_complete(document_hash, pdf, data)
      end

      defp parse_document(
             %{
               "event_type" => type,
               "event_time" => time,
               "event_hash" => hash,
               "meta" =>
                 %{
                   "related_document_hash" => document_hash,
                   "related_user_id" => _user_id,
                   "related_business_id" => _business_id,
                   "related_app_id" => _app_id
                 } = _meta
             } = data
           ),
           do: handle_document_change(document_hash, type, time, data)

      # failsafe for parsing bad documents
      defp parse_document(_), do: :ok

      # downloads the document from Eversign
      defp download_data(document_hash) do
        Logger.info("[Eversign] Downloading document #{document_hash}")

        document_hash
        |> Eversign.download_document()
        |> ok_data(document_hash)
      end

      # just returns the pdf document
      defp ok_data({:ok, pdf}, document_hash) do
        Logger.info("[Eversign] Successfully downloaded document #{document_hash}")
        pdf.body
      end

      # retries the request in 2 seconds
      defp ok_data({:error, error}, document_hash) do
        Logger.info("[Eversign] Retrying download of document #{document_hash} in 2 seconds: #{inspect(error)}")

        :timer.sleep(2_000)
        download_data(document_hash)
      end
    end
  end
end
