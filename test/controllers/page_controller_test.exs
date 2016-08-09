defmodule Mighty.PageControllerTest do
  use Mighty.ConnCase

  test "GET /" do
    conn = get conn(), "/"
    assert html_response(conn, 200) =~ "Hello"
  end
end
