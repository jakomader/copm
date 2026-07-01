defmodule Copm.Repo.Migrations.CreateTrackingEvents do
  use Ecto.Migration

  def change do
    create table(:tracking_events, primary_key: false) do
      add :tracking_id, :string, primary_key: true
      add :order_id, references(:orders, column: :order_id, type: :string, on_delete: :restrict), null: false
      add :event_ts, :utc_datetime, null: false
      add :status_code, :string, null: false
      add :status_description, :string
      add :location, :map, null: false
      add :operator_id, :string
      add :scanned_device_id, :string

      timestamps()
    end

    create index(:tracking_events, [:order_id])
    create index(:tracking_events, [:event_ts])
    create index(:tracking_events, [:status_code])
  end
end
