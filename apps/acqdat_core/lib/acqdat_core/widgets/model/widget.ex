defmodule AcqdatCore.Model.Widgets.Widget do
  alias AcqdatCore.Widgets.Schema.Widget
  alias AcqdatCore.Repo
  alias AcqdatCore.Model.Helper, as: ModelHelper
  import Ecto.Query

  def create(params) do
    changeset = Widget.changeset(%Widget{}, params)
    Repo.insert(changeset)
  end

  def get(id) when is_integer(id) do
    case Repo.get(Widget, id) do
      nil ->
        {:error, "not found"}

      widget ->
        {:ok, widget |> Repo.preload(:widget_type)}
    end
  end

  def delete(widget) do
    Repo.delete(widget)
  end

  def update(widget, params) do
    changeset = Widget.update_changeset(widget, params)
    Repo.update(changeset)
  end

  def get_all(%{page_size: page_size, page_number: page_number}) do
    Widget
    |> order_by(:id)
    |> Repo.paginate(page: page_number, page_size: page_size)
  end

  def get_all(%{page_size: page_size, page_number: page_number}, preloads) do
    paginated_widget_data =
      Widget |> order_by(:id) |> Repo.paginate(page: page_number, page_size: page_size)

    widget_data_with_preloads = paginated_widget_data.entries |> Repo.preload(preloads)

    ModelHelper.paginated_response(widget_data_with_preloads, paginated_widget_data)
  end
end