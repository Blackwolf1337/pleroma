# Pleroma: A lightweight social networking server
# Copyright © 2017-2021 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule Pleroma.Web.MastodonAPI.CustomEmojiView do
  use Pleroma.Web, :view

  alias Pleroma.Emoji
  alias Pleroma.Web.Endpoint

  def render("index.json", %{custom_emojis: custom_emojis}) do
    render_many(custom_emojis, __MODULE__, "show.json")
  end

  def render("show.json", %{custom_emoji: {shortcode, %Emoji{file: relative_url, tags: tags}}}) do
    url = Endpoint.url() |> URI.merge(relative_url) |> to_string()

    display_name = Enum.find(tags, fn x -> String.starts_with?(x, "display-name:") end)

    %{
      "shortcode" => shortcode,
      "static_url" => url,
      "visible_in_picker" => true,
      "url" => url,
      "tags" => tags,
      # Assuming that a comma is authorized in the category name
      "category" => get_category(tags, display_name)
    }
  end

  defp get_category(tags, nil), do: tags |> List.delete("Custom") |> Enum.join(",")

  defp get_category(_, display_name), do: String.replace(display_name, "display-name:", "")
end
