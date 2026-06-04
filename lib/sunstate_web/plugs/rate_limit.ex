defmodule SunstateWeb.Plugs.RateLimit do
  @moduledoc """
  Rate limiting plug using Cachex.

  Limits requests per IP address within a time window.
  """

  import Plug.Conn

  def init(opts) do
    %{
      max_requests: Keyword.get(opts, :max_requests, 60),
      window_ms: Keyword.get(opts, :window_ms, 60_000),
      cache: Keyword.get(opts, :cache, :sunstate_rate_limit)
    }
  end

  def call(conn, %{max_requests: max, window_ms: window, cache: cache}) do
    key = rate_limit_key(conn)

    case Cachex.get(cache, key) do
      {:ok, nil} ->
        Cachex.put(cache, key, 1, ttl: window)
        conn

      {:ok, count} when count < max ->
        Cachex.incr(cache, key)
        conn

      {:ok, _count} ->
        conn
        |> put_resp_content_type("text/plain")
        |> send_resp(429, "Too many requests. Please try again later.")
        |> halt()

      {:error, _} ->
        # If cache is unavailable, allow the request
        conn
    end
  end

  defp rate_limit_key(conn) do
    ip =
      conn.remote_ip
      |> :inet.ntoa()
      |> to_string()

    "rate_limit:#{ip}:#{conn.request_path}"
  end
end
