defmodule AcqdatCore.Seed.Helpers.WidgetHelpers do
  alias AcqdatCore.Repo
  alias AcqdatCore.Widgets.Schema.Widget
  alias AcqdatCore.Widgets.Schema.WidgetType
  alias AcqdatCore.Seed.Helpers.WidgetHelpers
  alias AcqdatCore.Widgets.Schema.Widget.VisualSettings
  alias AcqdatCore.Widgets.Schema.Widget.DataSettings
  import Tirexs.HTTP
  import Ecto.Query

  @non_value_types ~w(object list)a

  def find_or_create_widget_type(widget_name) do
    query = from(widget_type in WidgetType,
      where: widget_type.name == ^widget_name,
      select: widget_type
      )

    case Repo.all(query) do
      [] ->
        create_widget_type(widget_name)
      data ->
        List.first(data)
    end
  end

  def do_settings(%{visual: settings}, :visual, vendor_struct) do
    Enum.map(settings, fn {key, value} ->
      set_keys_from_vendor(key, value, Map.get(vendor_struct, key))
    end)
  end

  def do_settings(%{data: settings}, :data, _vendor_struct) do
    Enum.map(settings, fn {key, value} ->
      set_data_keys(key, value)
    end)
  end

  def set_data_keys(key, %{properties: properties} = value) when properties == %{} do
    %DataSettings{
      key: key,
      value: value.value,
      data_type: value.data_type,
      properties: []
    }
  end

  def set_data_keys(key, value) do
    %DataSettings{
      key: key,
      data_type: value.data_type,
      value: value.value,
      properties: Enum.map(value.properties, fn {key, value} ->
        set_data_keys(key, value)
      end)
    }
  end

  def set_keys_from_vendor(key, value, metadata) when is_list(value) do
    %VisualSettings{
      key: key,
      data_type: metadata.data_type,
      user_controlled: metadata.user_controlled,
      value: set_default_or_given_value(key, value, metadata),
      source: %{},
      properties: Enum.map(value,
        fn {child_key, child_value} ->
          set_keys_from_vendor(child_key, child_value, metadata.properties[child_key])
      end)
    }
  end

  def set_keys_from_vendor(key, value, metadata) when is_map(value) do
    %VisualSettings{
      key: key,
      data_type: metadata.data_type,
      user_controlled: metadata.user_controlled,
      source: %{},
      value: set_default_or_given_value(key, value, metadata),
      properties: []
    }
  end

  def set_default_or_given_value(key, value, metadata) do
    #TODO: Need to remove key workaround from here
    if metadata.data_type not in @non_value_types ||  key == :center do
      %{
        data:
        if Map.has_key?(value, :value) do
          value.value
        else
          metadata.default_value
        end
      }
    else
      %{}
    end
  end

  def seed_in_elastic() do
    Enum.each(Repo.all(Widget), fn widget ->
      WidgetHelpers.create("widgets", widget)
    end)
  end

  def create(type, params) do
    post("#{type}/_doc/#{params.id}",
      id: params.id,
      label: params.label,
      uuid: params.uuid,
      properties: params.properties,
      category: params.category
    )
  end

  defp create_widget_type(name) do
     params = %{
      name: name,
      vendor: name,
      module: "Elixir.AcqdatCore.Widgets.Schema.Vendors.#{name}",
      vendor_metadata: %{}
    }

    changeset = WidgetType.changeset(%WidgetType{}, params)
    {:ok, widget_type} = Repo.insert(changeset)
    widget_type
  end
end
