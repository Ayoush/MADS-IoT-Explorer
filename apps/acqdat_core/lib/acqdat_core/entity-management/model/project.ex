defmodule AcqdatCore.Model.EntityManagement.Project do
  import Ecto.Query
  alias AcqdatCore.Schema.EntityManagement.Project
  alias AcqdatCore.Schema.RoleManagement.User
  alias AcqdatCore.Schema.RoleManagement.Role
  alias AcqdatCore.Model.EntityManagement.Asset, as: AssetModel
  alias AcqdatCore.Model.EntityManagement.Sensor, as: SensorModel
  alias AcqdatCore.Model.Helper, as: ModelHelper
  alias AcqdatCore.Repo

  def hierarchy_data(org_id, project_id) do
    org_projects = fetch_projects(org_id, project_id)

    Enum.reduce(org_projects, [], fn project, acc ->
      entities = AssetModel.child_assets(project.id)
      sensors = SensorModel.get_by_project(project.id)
      map_data = Map.put_new(project, :assets, entities)
      acc ++ [Map.put_new(map_data, :sensors, sensors)]
    end)
  end

  def get_by_id(id) when is_integer(id) do
    case Repo.get(Project, id) do
      nil ->
        {:error, "not found"}

      project ->
        {:ok, project}
    end
  end

  def update_version(%Project{} = project) do
    changeset = Project.update_changeset(project, %{version: project.version + 1})
    Repo.update(changeset)
  end

  defp fetch_projects(org_id, project_id) do
    query =
      from(project in Project,
        where: project.org_id == ^org_id and project.id == ^project_id
      )

    Repo.all(query)
  end

  def get_all(%{page_size: page_size, page_number: page_number}) do
    Project |> order_by(:id) |> Repo.paginate(page: page_number, page_size: page_size)
  end

  def get_all(%{page_size: page_size, page_number: page_number}, preloads) do
    paginated_project_data =
      Project |> order_by(:id) |> Repo.paginate(page: page_number, page_size: page_size)

    project_data_with_preloads = paginated_project_data.entries |> Repo.preload(preloads)

    ModelHelper.paginated_response(project_data_with_preloads, paginated_project_data)
  end

  def check_adminship(user_id) do
    user_details = Repo.get!(User, user_id) |> Repo.preload([:role])

    case user_details.role.name == "admin" do
      true -> true
      false -> false
    end
  end
end