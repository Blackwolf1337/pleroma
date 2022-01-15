# Pleroma: A lightweight social networking server
# Copyright © 2017-2021 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule Pleroma.HTTP do
  @moduledoc """
    Wrapper for `Tesla.request/2`.
  """

  alias Pleroma.Config
  alias Pleroma.HTTP.AdapterHelper
  alias Pleroma.HTTP.Request
  alias Pleroma.HTTP.RequestBuilder, as: Builder
  alias Tesla.Client
  alias Tesla.Env

  require Logger

  @type t :: __MODULE__
  @type method() :: :get | :post | :put | :delete | :head

  defp get_tesla_adapter_and_children(_, {:error, reason}), do: raise "Proxy configuration parse error: #{reason}"

  defp get_tesla_adapter_and_children(:finch, {:ok, _proxy_type, _, _}), do: raise "Finch adapter does not support SOCKS proxies"

  defp get_tesla_adapter_and_children(:finch, proxy) do
    conn_opts =
      case proxy do
        {:ok, host, port} -> [proxy: {:http, host, port, []}]
        _ -> []
      end

    children = [{Finch, name: Pleroma.HTTP.FinchPool, conn_opts: conn_opts}]
    tesla_adapter = {Tesla.Adapter.Finch, name: Pleroma.HTTP.FinchPool}

    {tesla_adapter, children}
  end

  defp get_tesla_adapter_and_children(:hackney, _proxy) do
    tesla_adapter = Tesla.Adapter.Hackney
    children = []

    {tesla_adapter, children}
  end

  def setup_and_return_children! do
    parsed_proxy = AdapterHelper.parse_proxy(Config.get([:http, :proxy_url]))

    adapter =
      case Config.get([:http, :client]) do
        adapter when adapter in [:finch, :hackney] ->
          adapter

        nil ->
          case parsed_proxy do
            {:ok, {proxy_type, _, _}} when proxy_type in [:socks4, :socks5] -> :hackney
            _ -> :finch
          end

        unrecognized_adapter ->
          raise "No such adapter: #{unrecognized_adapter}"
      end

    {tesla_adapter, children} = get_tesla_adapter_and_children(adapter, parsed_proxy)

    Application.put_env(:tesla, :adapter, tesla_adapter)
    children
  end

  @doc """
  Performs GET request.

  See `Pleroma.HTTP.request/5`
  """
  @spec get(Request.url() | nil, Request.headers(), keyword()) ::
          nil | {:ok, Env.t()} | {:error, any()}
  def get(url, headers \\ [], options \\ [])
  def get(nil, _, _), do: nil
  def get(url, headers, options), do: request(:get, url, "", headers, options)

  @spec head(Request.url(), Request.headers(), keyword()) :: {:ok, Env.t()} | {:error, any()}
  def head(url, headers \\ [], options \\ []), do: request(:head, url, "", headers, options)

  @doc """
  Performs POST request.

  See `Pleroma.HTTP.request/5`
  """
  @spec post(Request.url(), String.t(), Request.headers(), keyword()) ::
          {:ok, Env.t()} | {:error, any()}
  def post(url, body, headers \\ [], options \\ []),
    do: request(:post, url, body, headers, options)

  @doc """
  Builds and performs http request.

  # Arguments:
  `method` - :get, :post, :put, :delete, :head
  `url` - full url
  `body` - request body
  `headers` - a keyworld list of headers, e.g. `[{"content-type", "text/plain"}]`
  `options` - custom, per-request middleware or adapter options

  # Returns:
  `{:ok, %Tesla.Env{}}` or `{:error, error}`

  """
  @spec request(method(), Request.url(), String.t(), Request.headers(), keyword()) ::
          {:ok, Env.t()} | {:error, any()}
  def request(method, url, body, headers, options) when is_binary(url) do
    uri = URI.parse(url)
    adapter_opts = AdapterHelper.options(uri, options || [])

    options = put_in(options[:adapter], adapter_opts)
    params = options[:params] || []
    request = build_request(method, headers, options, url, body, params)

    client = Tesla.client([Tesla.Middleware.FollowRedirects])

    request(client, request)
  end

  @spec request(Client.t(), keyword()) :: {:ok, Env.t()} | {:error, any()}
  def request(client, request), do: Tesla.request(client, request)

  defp build_request(method, headers, options, url, body, params) do
    Builder.new()
    |> Builder.method(method)
    |> Builder.headers(headers)
    |> Builder.opts(options)
    |> Builder.url(url)
    |> Builder.add_param(:body, :body, body)
    |> Builder.add_param(:query, :query, params)
    |> Builder.convert_to_keyword()
  end
end
