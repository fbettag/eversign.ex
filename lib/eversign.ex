defmodule Eversign do
  @moduledoc """
  Documentation for `Eversign` API Module.

  This API only contains everything required to generate Documents (for now).
  This module is specifically just the HTTP REST Layer.
  Specific functionality can be found in the individual documentation for each module.

  https://eversign.com/api/documentation
  """
  @eversign_api "https://api.eversign.com/api"
  @eversign_js "https://static.eversign.com/js/embedded-signing.js"

  import Eversign.RequestBuilder
  alias Phoenix.HTML.Tag

  @doc """
  Provides a Phoenix compatible script-tag embedding the eversign JavaScript API.

  ## Returns

  - `...`

  ## Examples

      iex> Eversign.javascript_tag
      %Phoenix.HTML.Tag{..}

  """
  def javascript_tag,
    do: Tag.tag(:script, type: "text/javascript", src: @eversign_js)

  @doc """
  Gets the current configuration from Config prepared for query arguments.

  ## Returns

  - `[access_key: "", business_id: 0, language: "en", sandbox: 1]`

  ## Examples

      iex> Eversign.config()
      [
        access_key: "",
        business_id: 0,
        language: "en",
        sandbox: 1
      ]

  """
  def config, do: Application.get_env(:eversign, :config)

  defp client do
    [
      {Tesla.Middleware.BaseUrl, @eversign_api},
      {Tesla.Middleware.Timeout, timeout: 30_000},
      {Tesla.Middleware.JSON, engine: Poison, engine_opts: [keys: :atoms]},
      {Tesla.Middleware.Headers,
       [
         {"User-Agent", "Elixir"},
         {"Content-Type", "application/json"}
       ]}
    ]
    |> Tesla.client()
  end

  defp add_credentials(request) do
    config = config()

    request
    |> add_param(:query, :access_key, Keyword.get(config, :access_key))
    |> add_param(:query, :business_id, Keyword.get(config, :business_id))
    |> add_param(:query, :language, Keyword.get(config, :language, "en"))
  end

  @doc """
  List all Documents.

  ## Parameters

  - client (Tesla.Client): [optional] Tesla Client for REST Connection
  - type (String): Eversign document type/stage, defaults to :all

  ## Returns

  - `{:ok, [%Eversign.Document{}]}`
  - `{:error, %Eversign.ErrorResponse{success:false, error: %{}}}` on failure

  ## Examples

      iex> Eversign.list_documents(:all)
      {:ok, [%{}]}

  """
  @spec list_documents(Tesla.Client.t() | nil, nil | atom()) :: {:error, Tesla.Client.t()} | {:ok, list(map())}
  def list_documents(client \\ client(), type \\ :all) do
    %{}
    |> method(:get)
    |> url("/document")
    |> add_credentials()
    |> add_param(:query, :type, type)
    |> Enum.into([])
    |> (&Tesla.request(client, &1)).()
    |> response_body()
  end

  def test do
    b64 = "test/example.pdf" |> File.read!() |> Base.encode64()

    Eversign.create_document(%{
      use_hidden_tags: 1,
      files: [
        %{name: "xyz.pdf", file_base64: b64}
      ],
      meta: %{
        customer_id: 123,
        offer_id: 123
      },
      signers: [
        %{id: 1, name: "Zack McCracken", email: "franz@bett.ag", order: 1}
      ]
    })
  end

  @doc """
  Create a Document.

  ## Parameters

  - client (Tesla.Client): [optional] Tesla Client for REST Connection
  - params (Map): Eversign parameters required for document creation

  ## Returns

  - `{:ok, %Eversign.Document{}}`
  - `{:error, %Eversign.ErrorResponse{success:false, error: %{}}}` on failure

  ## Examples

      iex> Eversign.create_document(%{
      ...>   use_hidden_tags: 1,
      ...>   files: [
      ...>     %{name: "xyz.pdf", file_base64: "base64"},
      ...>   ],
      ...>   meta: %{
      ...>     customer_id: 123,
      ...>     offer_id: 123,
      ...>   },
      ...>   signers: [
      ...>     %{id: 1, name: "Zack McCracken", email: "zack@example.int", order: 1},
      ...>     %{id: 2, name: "Fred McCracken", email: "fred@example.int", order: 2},
      ...>   ]
      ...> })
      {:ok, %{}}

  """
  @spec create_document(Tesla.Client.t() | nil, map()) :: {:error, Tesla.Client.t()} | {:ok, map()}
  def create_document(client \\ client(), %{} = params) do
    _optional_params = %{
      :is_draft => :body,
      :title => :body,
      :message => :body,
      :use_signer_order => :body,
      :reminders => :body,
      :require_all_signers => :body,
      :custom_requester_name => :body,
      :custom_requester_email => :body,
      :redirect => :body,
      :redirect_decline => :body,
      :client => :body,
      :expires => :body,
      :embedded_signing_enabled => :body,
      :flexible_signing => :body,
      :use_hidden_tags => :body,
      :signers => :body,
      :files => :body,
      :recipients => :body,
      :meta => :body,
      :fields => :body
    }

    %{}
    |> method(:post)
    |> url("/document")
    |> add_param(:body, :sandbox, Keyword.get(config(), :sandbox, 1))
    |> add_credentials()
    |> Map.put(:body, params)
    |> Enum.into([])
    |> (&Tesla.request(client, &1)).()
  end

  @doc """
  Get Embedded Signing URLs.

  ## Parameters

  - client (Tesla.Client): [optional] Tesla Client for REST Connection
  - document_hash (String): Eversign Document Hash

  ## Returns

  - `{:ok, %Eversign.SignerListResponse{}}` on success
  - `{:error, %Eversign.ErrorResponse{success:false, error: %{}}}` on failure

  ## Examples

      iex> Eversign.embedded_signing_url("ABCDEFGH1234")
      {:ok, %{signers: []}}
  """
  @spec get_embedded_signing_url(Tesla.Client.t() | nil, String.t()) :: {:error, Tesla.Client.t()} | {:ok, list()}
  def get_embedded_signing_url(client \\ client(), document_hash) do
    %{}
    |> method(:get)
    |> url("/document")
    |> add_credentials()
    |> add_param(:query, :document_hash, document_hash)
    |> Enum.into([])
    |> (&Tesla.request(client, &1)).()
  end

  @doc """
  Delete a Document which is still in draft or cancelled status.

  ## Parameters

  - client (Tesla.Client): [optional] Tesla Client for REST Connection
  - document_hash (String): Eversign Document Hash

  ## Returns

  - `{:ok, %Eversign.ErrorResponse{success: true}}` on success
  - `{:error, %Eversign.ErrorResponse{success:false, error: %{}}}` on failure

  """
  @spec delete_document(Tesla.Client.t() | nil, String.t()) :: {:ok, map()} | {:error, Tesla.Client.t()}
  def delete_document(client \\ client(), document_hash) do
    %{}
    |> method(:delete)
    |> url("/document")
    |> add_credentials()
    |> add_param(:query, :document_hash, document_hash)
    |> Enum.into([])
    |> (&Tesla.request(client, &1)).()
  end

  @doc """
  Cancels a Document.

  ## Parameters

  - client (Tesla.Client): [optional] Tesla Client for REST Connection
  - document_hash (String): Eversign Document Hash

  ## Returns

  - `{:ok, %Eversign.ErrorResponse{success: true}}` on success
  - `{:error, %Eversign.ErrorResponse{success:false, error: %{}}}` on failure

  """
  @spec cancel_document(Tesla.Client.t() | nil, String.t()) :: {:ok, map()} | {:error, Tesla.Client.t()}
  def cancel_document(client \\ client(), document_hash) do
    %{}
    |> method(:delete)
    |> url("/document")
    |> add_credentials()
    |> add_param(:query, :document_hash, document_hash)
    |> add_param(:query, :cancel, 1)
    |> Enum.into([])
    |> (&Tesla.request(client, &1)).()
  end

  @doc """
  Download a PDF of any document.

  ## Parameters

  - client (Tesla.Client): [optional] Tesla Client for REST Connection
  - document_hash (String): Eversign Document Hash
  - query (Keywords): [optional] Query parameters

  ## Returns

  - `{:ok, [] = pdf_bytes}` on success
  - `{:error, %Eversign.ErrorResponse{success:false, error: %{}}}` on failure

  ## Examples

      iex> Eversign.download_document("msFYActMfJHqNTKH8YSvF1", audit_trail: 1)
      {:ok, []}

  """
  @spec download_document(Tesla.Client.t() | nil, String.t(), keyword(String.t()) | nil) ::
          {:ok, binary()} | {:ok, map()} | {:error, Tesla.Client.t()}
  def download_document(client \\ client(), document_hash, query \\ []) do
    optional_params = %{
      :audit_trail => :query,
      :document_id => :query,
      :url_only => :query
    }

    %{}
    |> method(:get)
    |> url("/download_final_document")
    |> add_credentials()
    |> add_param(:query, :document_hash, document_hash)
    |> add_optional_params(optional_params, query)
    |> Enum.into([])
    |> (&Tesla.request(client, &1)).()
  end
end
