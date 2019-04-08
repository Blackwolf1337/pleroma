defmodule Pleroma.Web.Auth.MfcAuthenticator do
  alias Pleroma.User

  @behaviour Pleroma.Web.Auth.Authenticator
  @base Pleroma.Web.Auth.PleromaAuthenticator
  @controller Pleroma.Web.OAuth.OAuthController

  defdelegate get_registration(conn, params), to: @base

  defdelegate create_from_registration(conn, params, registration), to: @base

  def get_user(%Plug.Conn{} = conn, _params) do
    {name, password} =
      case conn.params do
        %{"authorization" => %{"name" => name, "password" => password}} ->
          {name, password}

        %{"grant_type" => "password", "username" => name, "password" => password} ->
          {name, password}
      end

    with {_, {:ok, user_data}} <-
           {:mfc_auth,
            Pleroma.Web.Mfc.Login.authenticate(
              name,
              password,
              to_string(:inet.ntoa(conn.remote_ip))
            )},
         {_, true} <-
           {:access_level_check,
            user_data["access_level"] >=
              Application.get_env(:pleroma, :mfc) |> Keyword.get(:minimum_access_level)},
         {_, %User{} = user} <-
           {:user_get,
            Pleroma.Web.Mfc.Utils.get_or_create_mfc_user(
              user_data["user_id"],
              user_data["username"],
              user_data["avatar_url"]
            )},
         {_, user} <-
           {:user_tag,
            User.tag(user, Pleroma.Web.Mfc.Utils.tags_for_level(user_data["access_level"]))} do
      {:ok, user}
    else
      error -> {:error, error}
    end
  end

  def handle_error(%Plug.Conn{} = conn, error) do
    # Note: `auth_params` arg (not necessarily equal to `conn.params`) will be added in upstream
    auth_params = conn.params["authorization"] || conn.params

    case error do
      {:get_user, {:error, {:access_level_check, _}}} ->
        conn
        |> Phoenix.Controller.put_flash(:error, "Only available for Premium accounts")
        |> @controller.authorize(auth_params)

      {:get_user, {:error, {:user_get, _}}} ->
        conn
        |> @controller.authorize(Map.put(auth_params, "registration", true))

      error ->
        @base.handle_error(conn, error)
    end
  end

  def auth_template, do: "show_mfc.html"

  def oauth_consumer_template, do: nil
end
