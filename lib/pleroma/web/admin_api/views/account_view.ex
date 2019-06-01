# Pleroma: A lightweight social networking server
# Copyright © 2017-2019 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule Pleroma.Web.AdminAPI.AccountView do
  use Pleroma.Web, :view

  alias Pleroma.User.Info
  alias Pleroma.Web.AdminAPI.AccountView

  def render("index.json", %{users: users, count: count, page_size: page_size}) do
    %{
      users: render_many(users, AccountView, "show.json", as: :user),
      count: count,
      page_size: page_size
    }
  end

  def render("show.json", %{user: user}) do
    %{
      "id" => user.id,
      "nickname" => user.nickname,
      "deactivated" => user.info.deactivated,
      "local" => user.local,
      "roles" => Info.roles(user.info),
      "tags" => user.tags || []
    }
  end

  def render("invite.json", %{invite: invite}) do
    %{
      "id" => invite.id,
      "token" => invite.token,
      "used" => invite.used,
      "expires_at" => invite.expires_at,
      "uses" => invite.uses,
      "max_use" => invite.max_use,
      "invite_type" => invite.invite_type
    }
  end

  def render("invites.json", %{invites: invites}) do
    %{
      invites: render_many(invites, AccountView, "invite.json", as: :invite)
    }
  end

  def render("created.json", %{user: user}) do
    %{
      type: "success",
      code: 200,
      data: %{
        nickname: user.nickname,
        email: user.email
      }
    }
  end

  def render("create-error.json", %{changeset: %Ecto.Changeset{changes: changes, errors: errors}}) do
    %{
      type: "error",
      code: 409,
      error: parse_error(errors),
      data: %{
        nickname: Map.get(changes, :nickname),
        email: Map.get(changes, :email)
      }
    }
  end

  defp parse_error([]), do: ""

  defp parse_error(errors) do
    ## when nickname is duplicate ap_id constraint error is raised
    nickname_error = Keyword.get(errors, :nickname) || Keyword.get(errors, :ap_id)
    email_error = Keyword.get(errors, :email)
    password_error = Keyword.get(errors, :password)

    cond do
      nickname_error ->
        "nickname #{elem(nickname_error, 0)}"

      email_error ->
        "email #{elem(email_error, 0)}"

      password_error ->
        "password #{elem(password_error, 0)}"

      true ->
        ""
    end
  end
end
