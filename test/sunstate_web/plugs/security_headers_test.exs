defmodule SunstateWeb.Plugs.SecurityHeadersTest do
  use SunstateWeb.ConnCase, async: true

  test "sets security headers", %{conn: conn} do
    conn = get(conn, ~p"/")

    assert get_resp_header(conn, "x-frame-options") == ["SAMEORIGIN"]
    assert get_resp_header(conn, "x-content-type-options") == ["nosniff"]
    assert get_resp_header(conn, "x-xss-protection") == ["1; mode=block"]
    assert get_resp_header(conn, "referrer-policy") == ["strict-origin-when-cross-origin"]
    assert get_resp_header(conn, "permissions-policy") != []
  end
end
