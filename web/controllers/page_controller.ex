defmodule Mighty.PageController do
  use Mighty.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
