# Pleroma: A lightweight social networking server
# Copyright © 2017-2020 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule Pleroma.Web.Frontend.DefaultController do
  defmacro __using__(_opts) do
    quote do
      import Pleroma.Frontend, only: [fe_file_path: 1, fe_file_path: 2]

      require Logger

      def index(conn, _params) do
        status = conn.status || 200

        {:ok, index_file_path} = fe_file_path("index.html", conn.private[:frontend][:config])

        conn
        |> put_resp_content_type("text/html")
        |> send_file(status, index_file_path)
      end

      def index_with_meta(conn, params) do
        index_with_generated_data(conn, params, [:metadata, :preload])
      end

      def index_with_preload(conn, params) do
        index_with_generated_data(conn, params, [:preload])
      end

      defp index_with_generated_data(conn, params, generators) do
        {:ok, path} = fe_file_path("index.html")
        {:ok, index_content} = File.read(path)

        generated =
          Enum.reduce(generators, "", fn generator, acc ->
            acc <> generate_data(conn, params, generator)
          end)

        response = String.replace(index_content, "<!--server-generated-meta-->", generated)

        html(conn, response)
      end

      def api_not_implemented(conn, _params) do
        conn
        |> put_status(404)
        |> json(%{error: "Not implemented"})
      end

      def empty(conn, _params) do
        conn
        |> put_status(204)
        |> text("")
      end

      def fallback(conn, _params) do
        conn
        |> put_status(404)
        |> text("Not found")
      end

      defp generate_data(conn, params, :preload) do
        try do
          Pleroma.Web.Preload.build_tags(conn, params)
        rescue
          e ->
            Logger.error(
              "Preloading for #{conn.request_path} failed.\n" <>
                Exception.format(:error, e, __STACKTRACE__)
            )

            ""
        end
      end

      defp generate_data(conn, params, :metadata) do
        try do
          Pleroma.Web.Metadata.build_tags(params)
        rescue
          e ->
            Logger.error(
              "Metadata rendering for #{conn.request_path} failed.\n" <>
                Exception.format(:error, e, __STACKTRACE__)
            )

            ""
        end
      end

      defoverridable index: 2,
                     index_with_meta: 2,
                     index_with_preload: 2,
                     api_not_implemented: 2,
                     empty: 2,
                     fallback: 2
    end
  end
end
