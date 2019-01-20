defmodule Pleroma.Uploaders.MFC.Image do
  @moduledoc """
  The module represents functions to convert images to different formats/resolustion.
  """

  require Logger

  defmodule Client do
    use Tesla

    def client() do
      middleware = [
        {
          Tesla.Middleware.BaseUrl,
          Pleroma.Config.get!([Pleroma.Uploaders.MFC, :image_conversion, :endpoint])
        },
        Tesla.Middleware.JSON
      ]

      Tesla.client(middleware)
    end
  end

  @convert_path "/api/v1/images"
  @default_postfix_preview ".preview.png"

  @doc "Convert image"
  @spec convert(Tesla.Client.t(), String.t()) :: :ok | :duplicate | {:error, String.t()}
  def convert(client, path) do
    config = Pleroma.Config.get!([Pleroma.Uploaders.MFC, :image_conversion])

    data = %{
      "client" => Keyword.fetch!(config, :client),
      "secret" => Keyword.fetch!(config, :secret),
      "source_key" => path,
      "versions" => %{
        "dest_key" => build_preview_url(Path.rootname(path)),
        "resolution" => "400x400",
        "method" => "resize"
      }
    }

    case Client.post(client, @convert_path, data) do
      {:ok, %{status: 200, body: versions}} ->
        versions

      error ->
        Logger.error(
          "#{__MODULE__}: HTTP request to conversion service failed: #{inspect(error)}"
        )

        {:error, "Conversion error"}
    end
  end

  @doc "Build preview url"
  @spec build_preview_url(String.t()) :: String.t()
  def build_preview_url(path) do
    postfix_preview_name =
      [Pleroma.Uploaders.MFC, :image_conversion, :postfix_preview_name]
      |> Pleroma.Config.get(@default_postfix_preview)

    "#{path}#{postfix_preview_name}"
  end
end
