# Pleroma: A lightweight social networking server
# Copyright © 2017-2022 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule Pleroma.Web.Plugs.EnsureUserTag.ModerationReportTriage do
  @moduledoc """
  Ensures account is privileged enough to do certain tasks regarding report triage.
  """

  import Pleroma.Web.TranslationHelpers
  import Plug.Conn

  alias Pleroma.User

  def init(options) do
    options
  end

  def call(%{assigns: %{user: %User{tags: [_] = tags}}} = conn, _) do
    if "moderation_tag:report-triage" in tags do
      conn
    else
      conn
      |> render_error(:forbidden, "User isn't privileged for report-triage.")
      |> halt()
    end
  end

  def call(conn, _) do
    conn
    |> render_error(:forbidden, "User isn't privileged for report-triage.")
    |> halt()
  end
end
