# Pleroma: A lightweight social networking server
# Copyright © 2017-2022 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule Pleroma.Web.Plugs.DissallowParam do
  @moduledoc """
  Forbids an action for specified parameters.
  """

  import Pleroma.Web.TranslationHelpers
  import Plug.Conn

  def init(options) do
    options
  end

  def call(%{params: params} = conn, {tag, regex}) do
    if allowed?(params |> Map.get(tag), regex),
      do: conn,
      else:
        conn |> render_error(:forbidden, "Call not allowed with specified parameter.") |> halt()
  end

  def call(conn, _) do
    conn
  end

  defp allowed?(nil, _) do
    true
  end

  defp allowed?(param_values, regex) do
    not Enum.any?(param_values, fn value -> String.match?(value, regex) end)
  end
end
