# Pleroma: A lightweight social networking server
# Copyright © 2017-2022 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule Pleroma.Web.ActivityPub.MRF.FixFormattingBullshit do
  @behaviour Pleroma.Web.ActivityPub.MRF.Policy

  @impl true
  def filter(
        %{
          "type" => "Create",
          "object" => %{"type" => "Note"}
        } = object
      )
  do
    content = object["object"]["content"] || ""

    # fix poast newlines
    content = Regex.replace(~r/<br><a[^>]*><\/a>/, content, "")

    # fix poast mention spaces
    content = Regex.replace(
      ~r/(<span class="recipients-inline">(?:[ ]*<span[^>]*><a[^>]*>.*?<\/a>[ ]*<\/span>)*) (<\/span>)/,
      content,
      "\\1\\2 "
    )

    {:ok, put_in(object["object"]["content"], content)}
  end

  @impl true
  def filter(object), do: {:ok, object}

  @impl true
  def describe, do: {:ok, %{}}
end
