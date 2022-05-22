# Pleroma: A lightweight social networking server
# Copyright © 2017-2022 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule Pleroma.Web.ActivityPub.MRF.ActorAvatarStylePolicy do
  alias Pleroma.Web.ActivityPub.Utils

  @moduledoc "Rewrite Misskey's isCat property into Pleroma's avatarStyle"
  @behaviour Pleroma.Web.ActivityPub.MRF.Policy

  defp cat do
    "🐈"
  end

  defp eligible_actor_types do
    ["Person", "Service"]
  end

  defp eligible_activity_types do
    ["Update", "Create"]
  end

  @impl true
  def filter(object) do
    is_activity = object["type"] in eligible_activity_types()

    inner_object =
      if is_activity do
        object["object"]
      else
        object
      end

    with {_, true} <- {:map, is_map(inner_object)},
         {_, true} <- {:type, inner_object["type"] in eligible_actor_types()},
         {_, true} <- {:cat, Map.get(inner_object, "isCat", false)} do
      inner_object =
        inner_object
        |> Map.put(Utils.pleroma_ns() <> "avatarStyle", cat())

      result =
        if is_activity do
          Map.put(object, "object", inner_object)
        else
          inner_object
        end

      {:ok, result}
    else
      _ -> {:ok, object}
    end
  end

  @impl true
  def describe, do: {:ok, %{}}
end
