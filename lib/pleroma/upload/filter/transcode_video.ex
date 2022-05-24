# Pleroma: A lightweight social networking server
# Copyright © 2017-2021 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule Pleroma.Upload.Filter.TranscodeVideo do
  @moduledoc """
  Transcodes uploaded video using ffmpeg
  """

  @behaviour Pleroma.Upload.Filter
  alias Pleroma.Upload

  @type conversion :: action :: String.t() | {action :: String.t(), opts :: String.t()}
  @type conversions :: conversion() | [conversion()]

  @spec filter(Upload.t()) :: {:ok, :atom} | {:error, String.t()}
  def filter(%Upload{name: name, tempfile: tempfile, path: path, content_type: "video" <> _} = upload) do
    try do
      # TODO move to config
      output_extension = "webm"

      input_extension =
        String.split(name, ".")
        |> List.last

      name = name |> String.replace_suffix("." <> input_extension, "." <> output_extension)
      path = path |> String.replace_suffix("." <> input_extension, "." <> output_extension)

      convert(tempfile, output_extension)

      {:ok, :filtered, %Upload{upload | name: name, path: path}}
    rescue
      e in ErlangError ->
        {:error, "#{__MODULE__}: #{inspect(e)}"}
    end
  end

  def filter(_), do: {:ok, :noop}

  defp convert(tempfile, output_extension) do
    tempfile_with_extension = tempfile <> "." <> output_extension

    # TODO allow additional args to be set in config
    args = [
      "-i",
      tempfile,
      "-y",
      tempfile_with_extension
    ]

    {_, 0} = System.cmd("ffmpeg", args)

    File.rm!(tempfile)
    File.rename!(tempfile_with_extension, tempfile)
  end
end
