defmodule SunstateWeb.PageController do
  use SunstateWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
