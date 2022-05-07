# Pleroma: A lightweight social networking server
# Copyright © 2017-2022 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule Pleroma.Web.Plugs.DissallowParamTest do
  use Pleroma.Web.ConnCase, async: true

  alias Pleroma.Web.Plugs.DissallowParam

  test "Doesn't allow a forbidden param" do
    conn_forbidden =
      build_conn(:get, "/", %{"tags" => ["foo", "moderation_tag:something", "bar"]})

    conn_allowed = build_conn(:get, "/", %{"tags" => ["foo", "bar"]})
    conn_no_value = build_conn()

    ret_conn_forbidden = DissallowParam.call(conn_forbidden, {"tags", ~r/^moderation_tag:.*/})
    ret_conn_allowed = DissallowParam.call(conn_allowed, {"tags", ~r/^moderation_tag:.*/})
    ret_conn_no_value = DissallowParam.call(conn_no_value, {"tags", ~r/^moderation_tag:.*/})

    assert ret_conn_forbidden.status == 403
    assert ret_conn_allowed == conn_allowed
    assert ret_conn_no_value == conn_no_value
  end
end
