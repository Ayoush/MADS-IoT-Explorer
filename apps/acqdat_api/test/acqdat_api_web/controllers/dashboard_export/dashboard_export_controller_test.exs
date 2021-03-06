defmodule AcqdatApiWeb.DashboardExport.DashboardExportControllerTest do
  use ExUnit.Case, async: true
  use AcqdatApiWeb.ConnCase
  use AcqdatCore.DataCase
  alias AcqdatCore.DashboardExport.Schema.DashboardExport
  alias AcqdatCore.Repo
  import AcqdatCore.Support.Factory

  describe "create/2" do
    setup :setup_conn

    setup do
      dashboard = insert(:dashboard)

      [dashboard: dashboard]
    end

    test "create exported url publicly", %{conn: conn, org: org, dashboard: dashboard} do
      data = %{is_secure: false}
      conn = post(conn, Routes.dashboard_export_path(conn, :create, org.id, dashboard.id), data)
      response = conn |> json_response(200)
      assert Map.has_key?(response, "url")
    end

    test "create exported url privately", %{conn: conn, org: org, dashboard: dashboard} do
      data = %{is_secure: true, password: "mads@1234"}
      conn = post(conn, Routes.dashboard_export_path(conn, :create, org.id, dashboard.id), data)
      response = conn |> json_response(200)
      assert Map.has_key?(response, "url")
    end
  end

  describe "update/2" do
    setup :setup_conn

    setup do
      dashboard = insert(:dashboard)

      [dashboard: dashboard]
    end

    test "update private exported dashboard to public", %{
      conn: conn,
      org: org,
      dashboard: dashboard
    } do
      private_dashboard_exp = insert(:dashboard_export, is_secure: true, password: "test123")
      data = %{is_secure: false}

      conn =
        put(
          conn,
          Routes.dashboard_export_path(
            conn,
            :update,
            org.id,
            dashboard.id,
            private_dashboard_exp.dashboard_uuid
          ),
          data
        )

      response = conn |> json_response(200)

      assert Map.has_key?(response, "is_secure")
      assert response["is_secure"] == false
    end

    test "update public exported dashboard to private", %{
      conn: conn,
      org: org,
      dashboard: dashboard
    } do
      private_dashboard_exp = insert(:dashboard_export, is_secure: false)
      data = %{is_secure: true, password: "test123"}

      conn =
        put(
          conn,
          Routes.dashboard_export_path(
            conn,
            :update,
            org.id,
            dashboard.id,
            private_dashboard_exp.dashboard_uuid
          ),
          data
        )

      response = conn |> json_response(200)

      assert Map.has_key?(response, "is_secure")
      assert response["is_secure"] == true
    end

    test "update public exported dashboard to private will fail if password is not provided", %{
      conn: conn,
      org: org,
      dashboard: dashboard
    } do
      private_dashboard_exp = insert(:dashboard_export, is_secure: false)
      data = %{is_secure: true}

      conn =
        put(
          conn,
          Routes.dashboard_export_path(
            conn,
            :update,
            org.id,
            dashboard.id,
            private_dashboard_exp.dashboard_uuid
          ),
          data
        )

      response = conn |> json_response(400)

      assert response == %{"errors" => %{"message" => %{"error" => "wrong information provided"}}}
    end
  end

  describe "show_credentials/2" do
    setup :setup_conn

    setup do
      dashboard = insert(:dashboard)

      [dashboard: dashboard]
    end

    test "shows credentials of the private dashboard_export", %{
      conn: conn,
      org: org,
      dashboard: dashboard
    } do
      private_dashboard_exp = insert(:dashboard_export, is_secure: true, password: "test123")

      conn =
        get(
          conn,
          Routes.dashboard_export_path(
            conn,
            :show_credentials,
            org.id,
            dashboard.id,
            private_dashboard_exp.dashboard_uuid
          )
        )

      response = conn |> json_response(200)

      assert Map.has_key?(response, "password")
      assert response["is_secure"] == true
      assert response["password"] == "test123"
    end

    test "credentials of public dashboard_export'll be null", %{
      conn: conn,
      org: org,
      dashboard: dashboard
    } do
      private_dashboard_exp = insert(:dashboard_export, is_secure: false)

      conn =
        get(
          conn,
          Routes.dashboard_export_path(
            conn,
            :show_credentials,
            org.id,
            dashboard.id,
            private_dashboard_exp.dashboard_uuid
          )
        )

      response = conn |> json_response(200)

      assert Map.has_key?(response, "password")
      assert response["is_secure"] == false
      refute response["password"]
    end

    test "it'll show error if dashboard_export doesn't exist", %{
      conn: conn,
      org: org,
      dashboard: dashboard
    } do
      conn =
        get(
          conn,
          Routes.dashboard_export_path(
            conn,
            :show_credentials,
            org.id,
            dashboard.id,
            -1
          )
        )

      response = conn |> json_response(404)

      assert response == %{"errors" => %{"message" => "Resource Not Found"}}
    end
  end
end
