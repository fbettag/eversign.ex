defmodule Eversign.RequestBuilder do
  @moduledoc """
  Helper functions for building Tesla requests
  """

  @doc """
  Specify the request method when building a request

  ## Parameters

  - request (Map) - Collected request options
  - m (atom) - Request method

  ## Returns

  Map
  """
  @spec method(map(), atom) :: map()
  def method(request, m) do
    Map.put_new(request, :method, m)
  end

  @doc """
  Specify the request method when building a request

  ## Parameters

  - request (Map) - Collected request options
  - u (String) - Request URL

  ## Returns

  Map
  """
  @spec url(map(), String.t()) :: map()
  def url(request, u) do
    Map.put_new(request, :url, u)
  end

  @doc """
  Add optional parameters to the request

  ## Parameters

  - request (Map) - Collected request options
  - definitions (Map) - Map of parameter name to parameter location.
  - options (KeywordList) - The provided optional parameters

  ## Returns

  Map
  """
  @spec add_optional_params(map(), %{optional(atom) => atom}, keyword()) :: map()
  def add_optional_params(request, _, []), do: request

  def add_optional_params(request, definitions, [{key, value} | tail]) do
    case definitions do
      %{^key => location} ->
        request
        |> add_param(location, key, value)
        |> add_optional_params(definitions, tail)

      _ ->
        add_optional_params(request, definitions, tail)
    end
  end

  @doc """
  Add optional parameters to the request

  ## Parameters

  - request (Map) - Collected request options
  - location (atom) - Where to put the parameter
  - key (atom) - The name of the parameter
  - value (any) - The value of the parameter

  ## Returns

  Map
  """
  @spec add_param(map(), atom, atom, any()) :: map()
  def add_param(request, :body, :body, value), do: Map.put(request, :body, value)

  def add_param(request, :body, key, value) do
    request
    |> Map.put_new_lazy(:body, &Tesla.Multipart.new/0)
    |> Map.update!(
      :body,
      &Tesla.Multipart.add_field(&1, key, Poison.encode!(value), headers: [{"content-type", "application/json"}])
    )
  end

  def add_param(request, :headers, key, value) do
    request
    |> Tesla.put_header(key, value)
  end

  def add_param(request, :file, name, path) do
    request
    |> Map.put_new_lazy(:body, &Tesla.Multipart.new/0)
    |> Map.update!(:body, &Tesla.Multipart.add_file(&1, path, name: name))
  end

  def add_param(request, :form, name, value) do
    request
    |> Map.update(:body, %{name => value}, &Map.put(&1, name, value))
  end

  def add_param(request, location, key, value) do
    Map.update(request, location, [{key, value}], &(&1 ++ [{key, value}]))
  end

  def response_body({status, %Tesla.Env{} = env}), do: {status, env.body}
end
