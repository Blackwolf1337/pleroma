# Pleroma: A lightweight social networking server
# Copyright © 2017-2018 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule Pleroma.Web.AdminAPI.AdminAPIControllerTest do
  use Pleroma.Web.ConnCase

  alias Pleroma.Repo
  alias Pleroma.User
  import Pleroma.Factory

  describe "/api/pleroma/admin/user" do
    test "Delete" do
      admin = insert(:user, info: %{is_admin: true})
      user = insert(:user)

      conn =
        build_conn()
        |> assign(:user, admin)
        |> put_req_header("accept", "application/json")
        |> delete("/api/pleroma/admin/user?nickname=#{user.nickname}")

      assert json_response(conn, 200) == user.nickname
    end

    test "Create" do
      admin = insert(:user, info: %{is_admin: true})

      conn =
        build_conn()
        |> assign(:user, admin)
        |> put_req_header("accept", "application/json")
        |> post("/api/pleroma/admin/user", %{
          "nickname" => "lain",
          "email" => "lain@example.org",
          "password" => "test"
        })

      assert json_response(conn, 200) == "lain"
    end
  end

  describe "/api/pleroma/admin/user/follow" do
    test "allows to force-follow another user" do
      admin = insert(:user, info: %{is_admin: true})
      user = insert(:user)
      follower = insert(:user)

      _conn =
        build_conn()
        |> assign(:user, admin)
        |> put_req_header("accept", "application/json")
        |> post("/api/pleroma/admin/user/follow", %{
          "follower" => follower.nickname,
          "followed" => user.nickname
        })

      user = Repo.get(User, user.id)
      follower = Repo.get(User, follower.id)

      assert User.following?(follower, user)
    end
  end

  describe "/api/pleroma/admin/user/unfollow" do
    test "allows to force-unfollow another user" do
      admin = insert(:user, info: %{is_admin: true})
      user = insert(:user)
      follower = insert(:user)

      User.follow(follower, user)

      _conn =
        build_conn()
        |> assign(:user, admin)
        |> put_req_header("accept", "application/json")
        |> post("/api/pleroma/admin/user/unfollow", %{
          "follower" => follower.nickname,
          "followed" => user.nickname
        })

      user = Repo.get(User, user.id)
      follower = Repo.get(User, follower.id)

      refute User.following?(follower, user)
    end
  end

  describe "PUT /api/pleroma/admin/users/tag" do
    setup do
      admin = insert(:user, info: %{is_admin: true})
      user1 = insert(:user, %{tags: ["x"]})
      user2 = insert(:user, %{tags: ["y"]})
      user3 = insert(:user, %{tags: ["unchanged"]})

      conn =
        build_conn()
        |> assign(:user, admin)
        |> put_req_header("accept", "application/json")
        |> put(
          "/api/pleroma/admin/users/tag?nicknames[]=#{user1.nickname}&nicknames[]=#{
            user2.nickname
          }&tags[]=foo&tags[]=bar"
        )

      %{conn: conn, user1: user1, user2: user2, user3: user3}
    end

    test "it appends specified tags to users with specified nicknames", %{
      conn: conn,
      user1: user1,
      user2: user2
    } do
      assert json_response(conn, :no_content)
      assert Repo.get(User, user1.id).tags == ["x", "foo", "bar"]
      assert Repo.get(User, user2.id).tags == ["y", "foo", "bar"]
    end

    test "it does not modify tags of not specified users", %{conn: conn, user3: user3} do
      assert json_response(conn, :no_content)
      assert Repo.get(User, user3.id).tags == ["unchanged"]
    end
  end

  describe "DELETE /api/pleroma/admin/users/tag" do
    setup do
      admin = insert(:user, info: %{is_admin: true})
      user1 = insert(:user, %{tags: ["x"]})
      user2 = insert(:user, %{tags: ["y", "z"]})
      user3 = insert(:user, %{tags: ["unchanged"]})

      conn =
        build_conn()
        |> assign(:user, admin)
        |> put_req_header("accept", "application/json")
        |> delete(
          "/api/pleroma/admin/users/tag?nicknames[]=#{user1.nickname}&nicknames[]=#{
            user2.nickname
          }&tags[]=x&tags[]=z"
        )

      %{conn: conn, user1: user1, user2: user2, user3: user3}
    end

    test "it removes specified tags from users with specified nicknames", %{
      conn: conn,
      user1: user1,
      user2: user2
    } do
      assert json_response(conn, :no_content)
      assert Repo.get(User, user1.id).tags == []
      assert Repo.get(User, user2.id).tags == ["y"]
    end

    test "it does not modify tags of not specified users", %{conn: conn, user3: user3} do
      assert json_response(conn, :no_content)
      assert Repo.get(User, user3.id).tags == ["unchanged"]
    end
  end

  describe "/api/pleroma/admin/permission_group" do
    test "GET is giving user_info" do
      admin = insert(:user, info: %{is_admin: true})

      conn =
        build_conn()
        |> assign(:user, admin)
        |> put_req_header("accept", "application/json")
        |> get("/api/pleroma/admin/permission_group/#{admin.nickname}")

      assert json_response(conn, 200) == %{
               "is_admin" => true,
               "is_moderator" => false
             }
    end

    test "/:right POST, can add to a permission group" do
      admin = insert(:user, info: %{is_admin: true})
      user = insert(:user)

      conn =
        build_conn()
        |> assign(:user, admin)
        |> put_req_header("accept", "application/json")
        |> post("/api/pleroma/admin/permission_group/#{user.nickname}/admin")

      assert json_response(conn, 200) == %{
               "is_admin" => true
             }
    end

    test "/:right DELETE, can remove from a permission group" do
      admin = insert(:user, info: %{is_admin: true})
      user = insert(:user, info: %{is_admin: true})

      conn =
        build_conn()
        |> assign(:user, admin)
        |> put_req_header("accept", "application/json")
        |> delete("/api/pleroma/admin/permission_group/#{user.nickname}/admin")

      assert json_response(conn, 200) == %{
               "is_admin" => false
             }
    end
  end

  describe "PUT /api/pleroma/admin/activation_status" do
    setup %{conn: conn} do
      admin = insert(:user, info: %{is_admin: true})

      conn =
        conn
        |> assign(:user, admin)
        |> put_req_header("accept", "application/json")

      %{conn: conn}
    end

    test "deactivates the user", %{conn: conn} do
      user = insert(:user)

      conn =
        conn
        |> put("/api/pleroma/admin/activation_status/#{user.nickname}", %{status: false})

      user = Repo.get(User, user.id)
      assert user.info.deactivated == true
      assert json_response(conn, :no_content)
    end

    test "activates the user", %{conn: conn} do
      user = insert(:user, info: %{deactivated: true})

      conn =
        conn
        |> put("/api/pleroma/admin/activation_status/#{user.nickname}", %{status: true})

      user = Repo.get(User, user.id)
      assert user.info.deactivated == false
      assert json_response(conn, :no_content)
    end

    test "returns 403 when requested by a non-admin", %{conn: conn} do
      user = insert(:user)

      conn =
        conn
        |> assign(:user, user)
        |> put("/api/pleroma/admin/activation_status/#{user.nickname}", %{status: false})

      assert json_response(conn, :forbidden)
    end
  end

  describe "POST /api/pleroma/admin/email_invite, with valid config" do
    setup do
      registrations_open = Pleroma.Config.get([:instance, :registrations_open])
      invites_enabled = Pleroma.Config.get([:instance, :invites_enabled])
      Pleroma.Config.put([:instance, :registrations_open], false)
      Pleroma.Config.put([:instance, :invites_enabled], true)

      on_exit(fn ->
        Pleroma.Config.put([:instance, :registrations_open], registrations_open)
        Pleroma.Config.put([:instance, :invites_enabled], invites_enabled)
        :ok
      end)

      [user: insert(:user, info: %{is_admin: true})]
    end

    test "sends invitation and returns 204", %{conn: conn, user: user} do
      recipient_email = "foo@bar.com"
      recipient_name = "J. D."

      conn =
        conn
        |> assign(:user, user)
        |> post("/api/pleroma/admin/email_invite?email=#{recipient_email}&name=#{recipient_name}")

      assert json_response(conn, :no_content)

      token_record = List.last(Pleroma.Repo.all(Pleroma.UserInviteToken))
      assert token_record
      refute token_record.used

      Swoosh.TestAssertions.assert_email_sent(
        Pleroma.UserEmail.user_invitation_email(
          user,
          token_record,
          recipient_email,
          recipient_name
        )
      )
    end

    test "it returns 403 if requested by a non-admin", %{conn: conn} do
      non_admin_user = insert(:user)

      conn =
        conn
        |> assign(:user, non_admin_user)
        |> post("/api/pleroma/admin/email_invite?email=foo@bar.com&name=JD")

      assert json_response(conn, :forbidden)
    end
  end

  describe "POST /api/pleroma/admin/email_invite, with invalid config" do
    setup do
      [user: insert(:user, info: %{is_admin: true})]
    end

    test "it returns 500 if `invites_enabled` is not enabled", %{conn: conn, user: user} do
      registrations_open = Pleroma.Config.get([:instance, :registrations_open])
      invites_enabled = Pleroma.Config.get([:instance, :invites_enabled])
      Pleroma.Config.put([:instance, :registrations_open], false)
      Pleroma.Config.put([:instance, :invites_enabled], false)

      on_exit(fn ->
        Pleroma.Config.put([:instance, :registrations_open], registrations_open)
        Pleroma.Config.put([:instance, :invites_enabled], invites_enabled)
        :ok
      end)

      conn =
        conn
        |> assign(:user, user)
        |> post("/api/pleroma/admin/email_invite?email=foo@bar.com&name=JD")

      assert json_response(conn, :internal_server_error)
    end

    test "it returns 500 if `registrations_open` is enabled", %{conn: conn, user: user} do
      registrations_open = Pleroma.Config.get([:instance, :registrations_open])
      invites_enabled = Pleroma.Config.get([:instance, :invites_enabled])
      Pleroma.Config.put([:instance, :registrations_open], true)
      Pleroma.Config.put([:instance, :invites_enabled], true)

      on_exit(fn ->
        Pleroma.Config.put([:instance, :registrations_open], registrations_open)
        Pleroma.Config.put([:instance, :invites_enabled], invites_enabled)
        :ok
      end)

      conn =
        conn
        |> assign(:user, user)
        |> post("/api/pleroma/admin/email_invite?email=foo@bar.com&name=JD")

      assert json_response(conn, :internal_server_error)
    end
  end

  test "/api/pleroma/admin/invite_token" do
    admin = insert(:user, info: %{is_admin: true})

    conn =
      build_conn()
      |> assign(:user, admin)
      |> put_req_header("accept", "application/json")
      |> get("/api/pleroma/admin/invite_token")

    assert conn.status == 200
  end

  test "/api/pleroma/admin/password_reset" do
    admin = insert(:user, info: %{is_admin: true})
    user = insert(:user)

    conn =
      build_conn()
      |> assign(:user, admin)
      |> put_req_header("accept", "application/json")
      |> get("/api/pleroma/admin/password_reset?nickname=#{user.nickname}")

    assert conn.status == 200
  end

  describe "GET /api/pleroma/admin/users" do
    test "renders users array for the first page" do
      admin = insert(:user, info: %{is_admin: true})
      user = insert(:user)

      conn =
        build_conn()
        |> assign(:user, admin)
        |> get("/api/pleroma/admin/users?page=1")

      assert json_response(conn, 200) == %{
               "count" => 2,
               "page_size" => 50,
               "users" => [
                 %{
                   "deactivated" => admin.info.deactivated,
                   "id" => admin.id,
                   "nickname" => admin.nickname,
                   "roles" => %{"admin" => true, "moderator" => false}
                 },
                 %{
                   "deactivated" => user.info.deactivated,
                   "id" => user.id,
                   "nickname" => user.nickname,
                   "roles" => %{"admin" => false, "moderator" => false}
                 }
               ]
             }
    end

    test "renders empty array for the second page" do
      admin = insert(:user, info: %{is_admin: true})
      insert(:user)

      conn =
        build_conn()
        |> assign(:user, admin)
        |> get("/api/pleroma/admin/users?page=2")

      assert json_response(conn, 200) == %{
               "count" => 2,
               "page_size" => 50,
               "users" => []
             }
    end

    test "regular search" do
      admin = insert(:user, info: %{is_admin: true})
      user = insert(:user, nickname: "bob")

      conn =
        build_conn()
        |> assign(:user, admin)
        |> get("/api/pleroma/admin/users?query=bo")

      assert json_response(conn, 200) == %{
               "count" => 1,
               "page_size" => 50,
               "users" => [
                 %{
                   "deactivated" => user.info.deactivated,
                   "id" => user.id,
                   "nickname" => user.nickname,
                   "roles" => %{"admin" => false, "moderator" => false}
                 }
               ]
             }
    end

    test "regular search with page size" do
      admin = insert(:user, info: %{is_admin: true})
      user = insert(:user, nickname: "bob")
      user2 = insert(:user, nickname: "bo")

      conn =
        build_conn()
        |> assign(:user, admin)
        |> get("/api/pleroma/admin/users?query=bo&page_size=1&page=1")

      assert json_response(conn, 200) == %{
               "count" => 2,
               "page_size" => 1,
               "users" => [
                 %{
                   "deactivated" => user.info.deactivated,
                   "id" => user.id,
                   "nickname" => user.nickname,
                   "roles" => %{"admin" => false, "moderator" => false}
                 }
               ]
             }

      conn =
        build_conn()
        |> assign(:user, admin)
        |> get("/api/pleroma/admin/users?query=bo&page_size=1&page=2")

      assert json_response(conn, 200) == %{
               "count" => 2,
               "page_size" => 1,
               "users" => [
                 %{
                   "deactivated" => user2.info.deactivated,
                   "id" => user2.id,
                   "nickname" => user2.nickname,
                   "roles" => %{"admin" => false, "moderator" => false}
                 }
               ]
             }
    end

    test "only local users" do
      admin = insert(:user, info: %{is_admin: true}, nickname: "john")
      user = insert(:user, nickname: "bob")

      insert(:user, nickname: "bobb", local: false)

      conn =
        build_conn()
        |> assign(:user, admin)
        |> get("/api/pleroma/admin/users?query=bo&local_only=true")

      assert json_response(conn, 200) == %{
               "count" => 1,
               "page_size" => 50,
               "users" => [
                 %{
                   "deactivated" => user.info.deactivated,
                   "id" => user.id,
                   "nickname" => user.nickname,
                   "roles" => %{"admin" => false, "moderator" => false}
                 }
               ]
             }
    end

    test "only local users with no query" do
      admin = insert(:user, info: %{is_admin: true}, nickname: "john")
      user = insert(:user, nickname: "bob")

      insert(:user, nickname: "bobb", local: false)

      conn =
        build_conn()
        |> assign(:user, admin)
        |> get("/api/pleroma/admin/users?local_only=true")

      assert json_response(conn, 200) == %{
               "count" => 2,
               "page_size" => 50,
               "users" => [
                 %{
                   "deactivated" => admin.info.deactivated,
                   "id" => admin.id,
                   "nickname" => admin.nickname,
                   "roles" => %{"admin" => true, "moderator" => false}
                 },
                 %{
                   "deactivated" => user.info.deactivated,
                   "id" => user.id,
                   "nickname" => user.nickname,
                   "roles" => %{"admin" => false, "moderator" => false}
                 }
               ]
             }
    end
  end

  test "PATCH /api/pleroma/admin/users/:nickname/toggle_activation" do
    admin = insert(:user, info: %{is_admin: true})
    user = insert(:user)

    conn =
      build_conn()
      |> assign(:user, admin)
      |> patch("/api/pleroma/admin/users/#{user.nickname}/toggle_activation")

    assert json_response(conn, 200) ==
             %{
               "deactivated" => !user.info.deactivated,
               "id" => user.id,
               "nickname" => user.nickname,
               "roles" => %{"admin" => false, "moderator" => false}
             }
  end
end
