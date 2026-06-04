defmodule SunstateWeb.Plugs.RateLimitTest do
  use SunstateWeb.ConnCase, async: false

  alias SunstateWeb.Plugs.RateLimit

  setup do
    # Clear the rate limit cache before each test
    Cachex.clear(:sunstate_rate_limit)
    :ok
  end

  test "allows requests under the limit", %{conn: conn} do
    opts = RateLimit.init(max_requests: 5, window_ms: 60_000)

    conn = %{conn | request_path: "/test-rate-limit"}

    Enum.each(1..5, fn _ ->
      result = RateLimit.call(conn, opts)
      refute result.halted
    end)
  end

  test "blocks requests over the limit", %{conn: conn} do
    opts = RateLimit.init(max_requests: 3, window_ms: 60_000)

    conn = %{conn | request_path: "/test-rate-block"}

    # Use up the limit
    Enum.each(1..3, fn _ ->
      RateLimit.call(conn, opts)
    end)

    # Next request should be blocked
    result = RateLimit.call(conn, opts)
    assert result.halted
    assert result.status == 429
  end
end
