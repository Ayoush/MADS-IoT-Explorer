defmodule AcqdatApiWeb.Alerts.PolicyController do
  @moduledoc """
  All the apis related to Policy
  """
  use AcqdatApiWeb, :controller
  alias AcqdatApi.Alerts.Policy
  plug AcqdatApiWeb.Plug.LoadOrg

  def index(conn, _params) do
    policies = Policy.list_policies()

    conn
    |> put_status(200)
    |> render("policies.json", %{policies: policies})
  end
end
