# Pleroma: A lightweight social networking server
# Copyright © 2017-2020 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule Mix.Tasks.Pleroma.Frontend do
  use Mix.Task

  import Mix.Pleroma

  # alias Pleroma.Config

  @shortdoc "Manages bundled Pleroma frontends"
  @moduledoc File.read!("docs/administration/CLI_tasks/frontend.md")

  @pleroma_gitlab_host "git.pleroma.social"
  @frontends %{
    "admin" => %{"project" => "pleroma/admin-fe"},
    "kenoma" => %{"project" => "lambadalambda/kenoma"},
    "mastodon" => %{"project" => "pleroma/mastofe"},
    "pleroma" => %{"project" => "pleroma/pleroma-fe"}
  }
  @known_frontends Map.keys(@frontends)

  @ref_stable "__stable__"
  @ref_develop "__develop__"
  @ref_local "__local__"

  def run(["install", "none" | _args]) do
    shell_info("Skipping frontend installation because none was requested")
  end

  def run(["install", unknown_fe | _args]) when unknown_fe not in @known_frontends do
    shell_error(
      "Frontend \"#{unknown_fe}\" is not known. Known frontends are: #{
        Enum.join(@known_frontends, ", ")
      }"
    )
  end

  def run(["install", frontend | args]) do
    log_level = Logger.level()
    Logger.configure(level: :warn)
    {:ok, _} = Application.ensure_all_started(:pleroma)

    {options, [], []} =
      OptionParser.parse(
        args,
        strict: [
          ref: :string,
          path: :string,
          develop: :boolean
        ]
      )

    ref =
      cond do
        options[:ref] ->
          options[:ref]

        options[:develop] ->
          @ref_develop

        options[:path] ->
          @ref_local

        true ->
          @ref_stable
      end

    %{"name" => bundle_name, "url" => bundle_url} =
      case options[:path] do
        nil ->
          get_bundle_meta(ref, @frontends[frontend]["project"])

        path ->
          version =
            path
            |> File.read!()
            |> Jason.decode!()
            |> Map.get("version")

          %{"name" => version, "url" => {:local, path}}
      end

    shell_info("Installing frontend #{frontend}, version: #{bundle_name}")

    dest =
      Path.join([
        Pleroma.Config.get!([:instance, :static_dir]),
        "frontends",
        frontend,
        bundle_name
      ])

    with :ok <- download_bundle(bundle_url, dest),
         :ok <- install_bundle(frontend, dest) do
      shell_info("Installed!")
    else
      {:error, error} ->
        shell_error("Error: #{inspect(error)}")
    end

    Logger.configure(level: log_level)
  end

  defp get_bundle_meta(@ref_develop, project) do
    url = "#{gitlab_api_url(project)}/repository/branches"

    %{status: 200, body: json} = Tesla.get!(http_client(), url)

    %{"name" => name, "commit" => %{"short_id" => last_commit_ref}} =
      Enum.find(json, & &1["default"])

    %{
      "name" => name,
      "url" => build_url(project, last_commit_ref)
    }
  end

  defp get_bundle_meta(@ref_stable, project) do
    url = "#{gitlab_api_url(project)}/releases"
    %{status: 200, body: json} = Tesla.get!(http_client(), url)

    [%{"commit" => %{"short_id" => commit_id}, "name" => name} | _] =
      Enum.sort(json, fn r1, r2 ->
        {:ok, date1, _offset} = DateTime.from_iso8601(r1["created_at"])
        {:ok, date2, _offset} = DateTime.from_iso8601(r2["created_at"])
        DateTime.compare(date1, date2) != :lt
      end)

    %{
      "name" => name,
      "url" => build_url(project, commit_id)
    }
  end

  defp get_bundle_meta(ref, project) do
    %{
      "name" => ref,
      "url" => build_url(project, ref)
    }
  end

  defp download_bundle({:local, _path}, _dir), do: :ok

  defp download_bundle(bundle_url, dir) do
    http_client = http_client()

    with {:ok, %{status: 200, body: zip_body}} <- Tesla.get(http_client, bundle_url),
         {:ok, unzipped} <- :zip.unzip(zip_body, [:memory]),
         filtered =
           Enum.filter(unzipped, fn
             {[?d, ?i, ?s, ?t, ?/ | _rest], _data} -> true
             _ -> false
           end),
         true <- length(filtered) > 0 do
      File.rm_rf!(dir)

      Enum.each(unzipped, fn {[?d, ?i, ?s, ?t, ?/ | path], data} ->
        file_path = Path.join(dir, path)

        file_path
        |> Path.dirname()
        |> File.mkdir_p!()

        File.write!(file_path, data)
      end)
    else
      {:ok, %{status: 404}} ->
        {:error, "Bundle not found"}

      false ->
        {:error, "Zip archive must contain \"dist\" folder"}

      error ->
        {:error, error}
    end
  end

  defp install_bundle("mastodon", base_path) do
    File.ls!(base_path) |> IO.inspect()
    required_paths = ["public/assets/sw.js", "public/packs"]

    with false <- Enum.all?(required_paths, &([base_path, &1] |> Path.join() |> File.exists?())) do
      build_bundle!("mastodon", base_path)
    end

    with :ok <- File.rename("#{base_path}/public/assets/sw.js", "#{base_path}/sw.js"),
         :ok <- File.rename("#{base_path}/public/packs", "#{base_path}/packs"),
         {:ok, _deleted_files} <- File.rm_rf("#{base_path}/public") do
      :ok
    else
      error ->
        {:error, error}
    end
  end

  defp install_bundle(_fe_name, _base_path), do: :ok

  defp build_bundle!("mastodon", base_path) do
    Pleroma.Utils.command_required!("yarn")
    {_out, 0} = System.cmd("yarn", ["install"], cd: base_path)
    {_out, 0} = System.cmd("yarn", ["run", "build"], cd: base_path)
  end

  defp build_bundle!(_frontend, base_path) do
    Pleroma.Utils.command_required!("yarn")
    {_out, 0} = System.cmd("yarn", [], cd: base_path)
    {_out, 0} = System.cmd("npm", ["run", "build"], cd: base_path)
  end

  defp gitlab_api_url(project),
    do: "https://#{@pleroma_gitlab_host}/api/v4/projects/#{URI.encode_www_form(project)}"

  defp build_url(project, ref),
    do: "https://#{@pleroma_gitlab_host}/#{project}/-/jobs/artifacts/#{ref}/download?job=build"

  defp http_client do
    middleware = [
      Tesla.Middleware.FollowRedirects,
      Tesla.Middleware.JSON
    ]

    Tesla.client(middleware)
  end
end
