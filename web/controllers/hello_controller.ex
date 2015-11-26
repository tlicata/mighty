defmodule Mighty.HelloController do
  use Mighty.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end

  def show(conn, %{"messenger" => messenger}) do
    conn
    |> put_flash(:info, "Success message")
    |> put_flash(:error, "Error message")
    |> render "show.html", messenger: messenger
  end
end
