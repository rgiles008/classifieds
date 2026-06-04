defmodule SunstateWeb.Plugs.SecurityHeaders do
  @moduledoc """
  Adds security headers to all responses.
  """

  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    conn
    |> put_resp_header("x-frame-options", "SAMEORIGIN")
    |> put_resp_header("x-content-type-options", "nosniff")
    |> put_resp_header("x-xss-protection", "1; mode=block")
    |> put_resp_header("referrer-policy", "strict-origin-when-cross-origin")
    |> put_resp_header(
      "permissions-policy",
      "camera=(), microphone=(), geolocation=(self), payment=()"
    )
  end
end
