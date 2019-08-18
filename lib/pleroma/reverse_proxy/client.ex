# Pleroma: A lightweight social networking server
# Copyright © 2017-2019 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule Pleroma.ReverseProxy.Client do
  @type status :: pos_integer()
  @type header_name :: String.t()
  @type header_value :: String.t()
  @type headers :: [{header_name(), header_value()}]

  @callback request(atom(), String.t(), headers(), String.t(), list()) ::
              {:ok, status(), headers(), reference() | map()}
              | {:ok, status(), headers()}
              | {:ok, reference()}
              | {:error, term()}

  @callback stream_body(reference() | pid() | map()) ::
              {:ok, binary()} | :done | {:error, String.t()}

  @callback close(reference() | pid() | map()) :: :ok

  def request(method, url, headers, body \\ "", opts \\ []) do
    client().request(method, url, headers, body, opts)
  end

  def stream_body(ref), do: client().stream_body(ref)

  def close(ref), do: client().close(ref)

  defp client do
    Pleroma.Config.get([Pleroma.ReverseProxy.Client], Pleroma.ReverseProxy.Client.Hackney)
  end
end
