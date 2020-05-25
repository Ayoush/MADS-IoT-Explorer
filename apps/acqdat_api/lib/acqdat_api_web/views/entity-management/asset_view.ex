defmodule AcqdatApiWeb.EntityManagement.AssetView do
  use AcqdatApiWeb, :view
  alias AcqdatApiWeb.EntityManagement.AssetView
  alias AcqdatApiWeb.EntityManagement.SensorView

  def render("asset_tree.json", %{asset: asset}) do
    assets =
      if Map.has_key?(asset, :assets) do
        render_many(asset.assets, AssetView, "asset_tree.json")
      end

    sensors =
      if Map.has_key?(asset, :sensors) do
        render_many(asset.sensors, SensorView, "sensor_tree.json")
      end

    %{
      type: "Asset",
      id: asset.id,
      parent_id: asset.parent_id,
      name: asset.name,
      properties: asset.properties,
      entities: (assets || []) ++ (sensors || [])
      # TODO: Need to uncomment below fields depending on the future usecases in the view
      # description: asset.description,
      # image_url: asset.image_url,
      # inserted_at: asset.inserted_at,
      # mapped_parameters: asset.mapped_parameters,
      # metadata: asset.metadata,
      # slug: asset.slug,
      # updated_at: asset.updated_at,
      # uuid: asset.uuid,
    }
  end

  def render("asset.json", %{asset: asset}) do
    %{
      type: "Asset",
      id: asset.id,
      name: asset.name,
      description: asset.description,
      properties: asset.properties,
      mapped_parameters: render_many(asset.mapped_parameters, AssetView, "parameters.json")
    }
  end

  def render("parameters.json", %{asset: asset}) do
    %{
      name: asset.name,
      uuid: asset.uuid,
      sensor_uuid: asset.sensor_uuid,
      parameter_uuid: asset.parameter_uuid
    }
  end
end