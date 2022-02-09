# Pleroma: A lightweight social networking server
# Copyright © 2017-2021 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule Pleroma.Web.MastodonAPI.CustomEmojiControllerTest do
  use Pleroma.Web.ConnCase, async: true

  test "with tags", %{conn: conn} do
    assert resp =
             conn
             |> get("/api/v1/custom_emojis")
             |> json_response_and_validate_schema(200)

    assert [emoji | _body] = resp
    assert Map.has_key?(emoji, "shortcode")
    assert Map.has_key?(emoji, "static_url")
    assert Map.has_key?(emoji, "tags")
    assert is_list(emoji["tags"])
    assert Map.has_key?(emoji, "category")
    assert Map.has_key?(emoji, "url")
    assert Map.has_key?(emoji, "visible_in_picker")
  end

  test "with display name", %{conn: conn} do
    assert resp =
            conn
            |> get("/api/v1/custom_emojis")
            |> json_response_and_validate_schema(200)

    assert test_pack =
            conn
            |> get("/api/pleroma/emoji/pack?name=test_pack_with_display_name")
            |> json_response_and_validate_schema(200)

    assert emoji = Enum.at(Enum.filter(resp, fn x -> x["shortcode"] == "blank6" end), 0)
    assert emoji["category"] == test_pack["pack"]["display-name"]
    assert Enum.member?(emoji["tags"], "display-name:#{test_pack["pack"]["display-name"]}")
    assert Enum.member?(emoji["tags"], "pack:test_pack_with_display_name")
  end

  test "without display name", %{conn: conn} do
    assert resp =
            conn
            |> get("/api/v1/custom_emojis")
            |> json_response_and_validate_schema(200)

    assert test_pack_name = "test_pack_no_display_name"

    assert emoji = Enum.at(Enum.filter(resp, fn x -> x["shortcode"] == "blank5" end), 0)
    assert emoji["category"] == "pack:#{test_pack_name}"
    assert Enum.at(emoji["tags"], 0) == "pack:#{test_pack_name}"
  end
end
