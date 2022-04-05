# Pleroma: A lightweight social networking server
# Copyright © 2017-2022 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule Pleroma.Web.Plugs.EnsureUserTag do
  @moduledoc """
  Ensures account is privileged enough to do certain tasks based on user tag.
  """

  import Pleroma.Web.TranslationHelpers
  import Plug.Conn

  alias Pleroma.User

  def init(options) do
    options
  end

  def call(%{assigns: %{user: %User{tags: [_] = tags}}} = conn, required_tag) do
    if required_tag in tags do
      conn
    else
      conn
      |> render_error(:forbidden, "User isn't privileged by user tag.")
      |> halt()
    end
  end

  def call(conn, _) do
    conn
    |> render_error(:forbidden, "User isn't privileged by user tag.")
    |> halt()
  end
end
