# Pleroma: A lightweight social networking server
# Copyright © 2017-2022 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule Pleroma.Web.ActivityPub.MRF.ActorAvatarStylePolicyTest do
  use Pleroma.DataCase, async: true
  import Pleroma.Factory

  alias Pleroma.Web.ActivityPub.Builder
  alias Pleroma.Web.ActivityPub.MRF.ActorAvatarStylePolicy
  alias Pleroma.Web.ActivityPub.Utils

  describe "turns isCat into avatarStyle" do
    test "with Update activity" do
      actor = insert(:user, %{local: false})

      {:ok, message, _} =
        Builder.update(
          actor,
          %{
            "id" => actor.ap_id,
            "type" => "Person",
            "name" => "some name",
            "isCat" => true
          }
        )

      assert {:ok, filtered} = ActorAvatarStylePolicy.filter(message)

      context = Utils.parse_json_ld_context(filtered)

      {:ok, avatar_style} =
        Utils.lookup_json_ld_key(filtered["object"], context, Utils.pleroma_ns() <> "avatarStyle")

      assert avatar_style == "🐈"
    end

    test "with Person object" do
      actor = insert(:user, %{local: false})

      message = %{
        "id" => actor.ap_id,
        "type" => "Person",
        "name" => "some name",
        "isCat" => true
      }

      assert {:ok, filtered} = ActorAvatarStylePolicy.filter(message)

      context = Utils.parse_json_ld_context(filtered)

      {:ok, avatar_style} =
        Utils.lookup_json_ld_key(filtered, context, Utils.pleroma_ns() <> "avatarStyle")

      assert avatar_style == "🐈"
    end
  end
end
