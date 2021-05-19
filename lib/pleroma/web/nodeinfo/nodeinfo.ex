# Pleroma: A lightweight social networking server
# Copyright © 2017-2021 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule Pleroma.Web.Nodeinfo.Nodeinfo do
  alias Pleroma.Config
  alias Pleroma.Stats
  alias Pleroma.User
  alias Pleroma.Web.ActivityPub.MRF
  alias Pleroma.Web.Federator.Publisher

  # returns a nodeinfo 2.0 map, since 2.1 just adds a repository field
  # under software.
  def get_nodeinfo("2.0") do
    stats = Stats.get_stats()

    staff_accounts =
      User.all_superusers()
      |> Enum.map(fn u -> u.ap_id end)

    %{
      version: "2.0",
      software: %{
        name: Pleroma.Application.name() |> String.downcase(),
        version: Pleroma.Application.version()
      },
      protocols: Publisher.gather_nodeinfo_protocol_names(),
      services: %{
        inbound: [],
        outbound: []
      },
      openRegistrations: Config.get([:instance, :registrations_open]),
      usage: %{
        users: %{
          total: Map.get(stats, :user_count, 0)
        },
        localPosts: Map.get(stats, :status_count, 0)
      },
      metadata: %{
        nodeName: Config.get([:instance, :name]),
        nodeDescription: Config.get([:instance, :description]),
        private: !Config.get([:instance, :public], true),
        suggestions: %{
          enabled: false
        },
        staffAccounts: staff_accounts,
        federation: federation(),
        pollLimits: Config.get([:instance, :poll_limits]),
        postFormats: Config.get([:instance, :allowed_post_formats]),
        uploadLimits: %{
          general: Config.get([:instance, :upload_limit]),
          avatar: Config.get([:instance, :avatar_upload_limit]),
          banner: Config.get([:instance, :banner_upload_limit]),
          background: Config.get([:instance, :background_upload_limit])
        },
        fieldsLimits: %{
          maxFields: Config.get([:instance, :max_account_fields]),
          maxRemoteFields: Config.get([:instance, :max_remote_account_fields]),
          nameLength: Config.get([:instance, :account_field_name_length]),
          valueLength: Config.get([:instance, :account_field_value_length])
        },
        accountActivationRequired: Config.get([:instance, :account_activation_required], false),
        invitesEnabled: Config.get([:instance, :invites_enabled], false),
        mailerEnabled: Config.get([Pleroma.Emails.Mailer, :enabled], false),
        features: features(),
        restrictedNicknames: Config.get([Pleroma.User, :restricted_nicknames]),
        skipThreadContainment: Config.get([:instance, :skip_thread_containment], false)
      }
    }
  end

  def get_nodeinfo("2.1") do
    raw_response = get_nodeinfo("2.0")

    updated_software =
      raw_response
      |> Map.get(:software)
      |> Map.put(:repository, Pleroma.Application.repository())

    raw_response
    |> Map.put(:software, updated_software)
    |> Map.put(:version, "2.1")
  end

  def get_nodeinfo(_version) do
    {:error, :missing}
  end

  def features do
    [
      "pleroma_api",
      "mastodon_api",
      "mastodon_api_streaming",
      "polls",
      "pleroma_explicit_addressing",
      "shareable_emoji_packs",
      "multifetch",
      "pleroma:api/v1/notifications:include_types_filter",
      if Config.get([:media_proxy, :enabled]) do
        "media_proxy"
      end,
      if Config.get([:gopher, :enabled]) do
        "gopher"
      end,
      if Config.get([:chat, :enabled]) do
        "chat"
      end,
      if Config.get([:instance, :allow_relay]) do
        "relay"
      end,
      if Config.get([:instance, :safe_dm_mentions]) do
        "safe_dm_mentions"
      end,
      "pleroma_emoji_reactions",
      "pleroma_chat_messages"
    ]
    |> Enum.filter(& &1)
  end

  def federation do
    quarantined = Config.get([:instance, :quarantined_instances], [])

    if Config.get([:mrf, :transparency]) do
      {:ok, data} = MRF.describe()

      data
      |> Map.merge(%{quarantined_instances: quarantined})
    else
      %{}
    end
    |> Map.put(:enabled, Config.get([:instance, :federating]))
  end

  def fields_limits do
    %{
      max_fields: Config.get([:instance, :max_account_fields]),
      max_remote_fields: Config.get([:instance, :max_remote_account_fields]),
      name_length: Config.get([:instance, :account_field_name_length]),
      value_length: Config.get([:instance, :account_field_value_length])
    }
  end
end
