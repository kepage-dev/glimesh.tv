defmodule GlimeshWeb.UserPaymentsController do
  use GlimeshWeb, :controller

  alias Glimesh.Accounts
  alias GlimeshWeb.UserAuth

  def index(conn, _params) do
    user = conn.assigns.current_user

    params = Plug.Conn.Query.encode(%{
      "client_id" => Application.get_env(:stripity_stripe, :connect_client_id),
      "state" => Plug.CSRFProtection.get_csrf_token(),
      "suggested_capabilities" => ["transfers", "card_payments"],
      "stripe_user" => %{
        "email" => user.email
      }
    })

    stripe_oauth_url = "https://connect.stripe.com/express/oauth/authorize?" <> params

    IO.inspect(user)

    render(conn, "index.html",
      is_verified_streamer: !is_nil(user.stripe_user_id),
      stripe_oauth_url: stripe_oauth_url,
    )
  end

  def connect(conn, %{"state" => state, "code" => code}) do
    user = conn.assigns.current_user
#    Plug.CSRFProtection.valid_state_and_csrf_token?(state)
    case Glimesh.Payments.oauth_connect(user, code) do
      {:ok, _} ->
        conn
        |> put_flash(:info, "Stripe account linked successfully, welcome to the sub club!")
        |> redirect(to: Routes.user_payments_path(conn, :index))

      {:error, err} ->
        conn |> put_flash(:error, err)|> redirect(to: Routes.user_payments_path(conn, :index))
    end
  end

end