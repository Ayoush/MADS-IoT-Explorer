defmodule AcqdatApiWeb.UserWidgetControllerTest do
  use ExUnit.Case, async: true
  use AcqdatApiWeb.ConnCase
  use AcqdatCore.DataCase
  import AcqdatCore.Support.Factory

  describe "create/2" do
    setup :setup_conn

    test "user widget create", %{conn: conn} do
      widget = insert(:widget)
      user = insert(:user)

      params = %{
        user_id: user.id,
        widget_id: widget.id
      }

      conn = post(conn, Routes.user_path(conn, :create, params), %{})
      response = conn |> json_response(200)
      assert response == %{"Widget Added" => true}
    end

    test "fails if authorization header not found", %{conn: conn} do
      bad_access_token = "qwerty1234567uiop"

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{bad_access_token}")

      data = %{}
      conn = post(conn, Routes.user_path(conn, :create), data)
      result = conn |> json_response(403)
      assert result == %{"errors" => %{"message" => "Unauthorized"}}
    end

    test "fails if sent params are not unique", %{conn: conn} do
      widget = insert(:widget)
      user = insert(:user)

      params = %{
        user_id: user.id,
        widget_id: widget.id
      }

      conn = post(conn, Routes.user_path(conn, :create, params), %{})

      conn = post(conn, Routes.user_path(conn, :create, params), %{})
      response = conn |> json_response(400)

      assert response == %{
               "errors" => %{
                 "message" => %{"error" => %{"name" => ["has already been taken"]}}
               }
             }
    end

    test "fails if required resource are missing", %{conn: conn} do
      user = insert(:user)

      params = %{
        user_id: user.id,
        widget_id: 2
      }

      conn = post(conn, Routes.user_path(conn, :create, params), %{})

      response = conn |> json_response(404)
      assert response == %{"errors" => %{"message" => "Resource Not Found"}}
    end
  end

  describe "index/2" do
    setup :setup_conn

    test "User Widget Data", %{conn: conn} do
      widget = insert(:widget)
      user = insert(:user)

      params = %{
        user_id: user.id,
        widget_id: widget.id
      }

      conn = post(conn, Routes.user_path(conn, :create, params), %{})

      params = %{
        "user_id" => user.id,
        "page_size" => 100,
        "page_number" => 1
      }

      conn = get(conn, Routes.user_path(conn, :index, params))
      response = conn |> json_response(200)
      assert length(response["user_widgets"]) == 1
      assertion_user_widget = List.first(response["user_widgets"])
      assert assertion_user_widget["widget_id"] == widget.id
      assert assertion_user_widget["user_id"] == user.id
      assert assertion_user_widget["widget"]["widget_type_id"] == widget.widget_type_id
    end

    test "fails if invalid token in authorization header", %{conn: conn} do
      bad_access_token = "qwerty1234567qwerty12"
      user = insert(:user)

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{bad_access_token}")

      params = %{
        "user_id" => user.id,
        "page_size" => 100,
        "page_number" => 1
      }

      conn = get(conn, Routes.user_path(conn, :index, params))
      result = conn |> json_response(403)
      assert result == %{"errors" => %{"message" => "Unauthorized"}}
    end
  end
end
