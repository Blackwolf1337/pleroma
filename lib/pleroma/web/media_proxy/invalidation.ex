# Pleroma: A lightweight social networking server
# Copyright © 2017-2020 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule Pleroma.Web.MediaProxy.Invalidation do
  @moduledoc false

  @callback purge(list(String.t()), Keyword.t()) :: {:ok, list(String.t())} | {:error, String.t()}

  alias Pleroma.Config
  alias Pleroma.Web.MediaProxy

  def enabled, do: Config.get([:media_proxy, :invalidation, :enabled])

  @spec purge(list(String.t()) | String.t()) :: {:ok, list(String.t())} | {:error, String.t()}
  def purge(urls) do
    prepared_urls = prepare_urls(urls)

    if enabled() do
      do_purge(prepared_urls)
    else
      {:ok, prepared_urls}
    end
  end

  defp do_purge(urls) do
    provider = Config.get([:media_proxy, :invalidation, :provider])
    provider.purge(urls, Config.get(provider))
  end

  defp prepare_urls(urls) do
    urls
    |> List.wrap()
    |> Enum.map(&MediaProxy.url(&1))
  end
end