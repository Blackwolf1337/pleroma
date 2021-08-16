# Pleroma: A lightweight social networking server
# Copyright © 2017-2021 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule Mix.Tasks.Pleroma.Search.Meilisearch do
  require Logger
  require Pleroma.Constants

  import Mix.Pleroma
  import Ecto.Query

  def run(["index"]) do
    start_pleroma()

    endpoint = Pleroma.Config.get([Pleroma.Search.Meilisearch, :url])

    {:ok, _} =
      Pleroma.HTTP.post(
        "#{endpoint}/indexes/objects/settings/ranking-rules",
        Jason.encode!([
          "desc(id)",
          "typo",
          "words",
          "proximity",
          "attribute",
          "wordsPosition",
          "exactness"
        ])
      )

    Pleroma.Repo.chunk_stream(
      from(Pleroma.Object,
        # Only index public posts which are notes and have some text
        where:
          fragment("data->>'type' = 'Note'") and
            fragment("LENGTH(data->>'source') > 0") and
            fragment("data->'to' \\? ?", ^Pleroma.Constants.as_public())
      ),
      200,
      :batches
    )
    |> Stream.map(fn objects ->
      Enum.map(objects, fn object ->
        data = object.data
        %{id: object.id, source: data["source"], ap: data["id"]}
      end)
    end)
    |> Stream.each(fn objects ->
      {:ok, _} =
        Pleroma.HTTP.post(
          "#{endpoint}/indexes/objects/documents",
          Jason.encode!(objects)
        )

      IO.puts("Indexed #{Enum.count(objects)} entries")
    end)
    |> Stream.run()
  end

  def run(["clear"]) do
    start_pleroma()

    endpoint = Pleroma.Config.get([Pleroma.Search.Meilisearch, :url])

    {:ok, _} = Pleroma.HTTP.request(:delete, "#{endpoint}/indexes/objects/documents", "", [], [])
  end
end