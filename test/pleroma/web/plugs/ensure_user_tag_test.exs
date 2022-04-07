# Pleroma: A lightweight social networking server
# Copyright © 2017-2022 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule Pleroma.Web.Plugs.EnsureUserTagTest do
  use Pleroma.Web.ConnCase, async: true

  alias Pleroma.Web.Plugs.EnsureUserTag
  import Pleroma.Factory

  test "accepts a user that has the correct user tag" do
    user = insert(:user, tags: ["moderation_tag:report-triage"])

    user2 =
      insert(:user, tags: ["moderation_tag:report-triage", "moderation_tag:account-credentials"])

    conn = assign(build_conn(), :user, user)
    conn2 = assign(build_conn(), :user, user2)

    ret_conn = EnsureUserTag.call(conn, "moderation_tag:report-triage")
    ret_conn2 = EnsureUserTag.call(conn2, "moderation_tag:report-triage")
    ret_conn3 = EnsureUserTag.call(conn2, "moderation_tag:account-credentials")

    assert conn == ret_conn
    assert conn2 == ret_conn2
    assert conn2 == ret_conn3
  end

  test "denies a user that doesn't have the correct user" do
    user = insert(:user, tags: ["moderation_tag:report-triage"])

    conn =
      build_conn()
      |> assign(:user, user)
      |> EnsureUserTag.call("moderation_tag:something-else")

    assert conn.status == 403
  end

  test "denies when a user isn't set" do
    conn = EnsureUserTag.call(build_conn(), %{})

    assert conn.status == 403
  end
end
