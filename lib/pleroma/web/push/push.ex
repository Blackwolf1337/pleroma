# Pleroma: A lightweight social networking server
# Copyright © 2017-2019 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule Pleroma.Web.Push do
  use GenServer

  alias Pleroma.Repo
  alias Pleroma.User
  alias Pleroma.Activity
  alias Pleroma.Object
  alias Pleroma.Web.Push.Subscription
  alias Pleroma.Web.Metadata.Utils

  require Logger
  import Ecto.Query

  @types ["Create", "Follow", "Announce", "Like"]

  def start_link() do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def vapid_config() do
    Application.get_env(:web_push_encryption, :vapid_details, [])
  end

  def enabled() do
    case vapid_config() do
      [] -> false
      list when is_list(list) -> true
      _ -> false
    end
  end

  def send(notification) do
    if enabled() do
      GenServer.cast(Pleroma.Web.Push, {:send, notification})
    end
  end

  def init(:ok) do
    if !enabled() do
      Logger.warn("""
      VAPID key pair is not found. If you wish to enabled web push, please run

          mix web_push.gen.keypair

      and add the resulting output to your configuration file.
      """)

      :ignore
    else
      {:ok, nil}
    end
  end

  def handle_cast(
        {:send, %{activity: %{data: %{"type" => type}}, user_id: user_id} = notification},
        state
      )
      when type in @types do
    actor = User.get_cached_by_ap_id(notification.activity.data["actor"])

    type = Pleroma.Activity.mastodon_notification_type(notification.activity)

    Subscription
    |> where(user_id: ^user_id)
    |> preload(:token)
    |> Repo.all()
    |> Enum.filter(fn subscription ->
      get_in(subscription.data, ["alerts", type]) || false
    end)
    |> Enum.each(fn subscription ->
      sub = %{
        keys: %{
          p256dh: subscription.key_p256dh,
          auth: subscription.key_auth
        },
        endpoint: subscription.endpoint
      }

      body =
        Jason.encode!(%{
          title: format_title(notification),
          access_token: subscription.token.token,
          body: format_body(notification, actor),
          notification_id: notification.id,
          notification_type: type,
          icon: User.avatar_url(actor),
          preferred_locale: "en"
        })

      case WebPushEncryption.send_web_push(
             body,
             sub,
             Application.get_env(:web_push_encryption, :gcm_api_key)
           ) do
        {:ok, %{status_code: code}} when 400 <= code and code < 500 ->
          Logger.debug("Removing subscription record")
          Repo.delete!(subscription)
          :ok

        {:ok, %{status_code: code}} when 200 <= code and code < 300 ->
          :ok

        {:ok, %{status_code: code}} ->
          Logger.error("Web Push Notification failed with code: #{code}")
          :error

        _ ->
          Logger.error("Web Push Notification failed with unknown error")
          :error
      end
    end)

    {:noreply, state}
  end

  def handle_cast({:send, _}, state) do
    Logger.warn("Unknown notification type")
    {:noreply, state}
  end

  def format_body(
        %{activity: %{data: %{"type" => "Create", "object" => %{"content" => content}}}},
        actor
      ) do
    "@#{actor.nickname}: #{Utils.scrub_html_and_truncate(content, 80)}"
  end

  def format_body(
        %{activity: %{data: %{"type" => "Announce", "object" => activity_id}}},
        actor
      ) do
    %Activity{data: %{"object" => %{"id" => object_id}}} = Activity.get_by_ap_id(activity_id)
    %Object{data: %{"content" => content}} = Object.get_by_ap_id(object_id)

    "@#{actor.nickname} reposted: #{Utils.scrub_html_and_truncate(content, 80)}"
  end

  def format_body(
        %{activity: %{data: %{"type" => type}}},
        actor
      )
      when type in ["Follow", "Like"] do
    case type do
      "Follow" -> "@#{actor.nickname} has followed you"
      "Like" -> "@#{actor.nickname} has favorited your post"
    end
  end

  defp format_title(%{activity: %{data: %{"type" => type}}}) do
    case type do
      "Create" -> "New Mention"
      "Follow" -> "New Follower"
      "Announce" -> "New Repost"
      "Like" -> "New Favorite"
    end
  end
end
