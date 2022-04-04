# Pleroma: A lightweight social networking server
# Copyright © 2017-2022 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule Pleroma.Web.Plugs.EnsureUserTag.ModerationReportTriageTest do
  use Pleroma.Web.ConnCase, async: true

  alias Pleroma.Web.Plugs.EnsureUserTag.ModerationReportTriage
  import Pleroma.Factory

  test "accepts a user that has the user tag moderation_tag:report-triage" do
    user = insert(:user, tags: ["moderation_tag:report-triage"])

    conn = assign(build_conn(), :user, user)

    ret_conn = ModerationReportTriage.call(conn, %{})

    assert conn == ret_conn
  end

  test "denies a user that doesn't have the user tag moderation_tag:report-triage" do
    user = insert(:user)

    conn =
      build_conn()
      |> assign(:user, user)
      |> ModerationReportTriage.call(%{})

    assert conn.status == 403
  end

  test "denies when a user isn't set" do
    conn = ModerationReportTriage.call(build_conn(), %{})

    assert conn.status == 403
  end
end
