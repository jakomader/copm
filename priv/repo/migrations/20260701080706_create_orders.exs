defmodule Copm.Repo.Migrations.CreateOrders do
  use Ecto.Migration

  def change do
    create table(:orders, primary_key: false) do
      add :order_id, :string, primary_key: true
      add :contract_id, :string, null: false
      add :client_id, :string, null: false
      add :user_id, :string, null: false
      add :order_status, :string, null: false
      add :order_type, :string, null: false
      add :created_at, :utc_datetime, null: false
      add :confirmed_at, :utc_datetime, null: false
      add :sender, :map, null: false
      add :receiver, :map, null: false
      add :route_from, :string, null: false
      add :route_to, :string, null: false
      add :transit_points, {:array, :string}
      add :carrier, :map, null: false
      add :flight_number, :string
      add :vehicle_number, :string
      add :awb_number, :string
      add :cmr_number, :string
      add :cargo_description, :string, null: false
      add :cargo_weight, :decimal, null: false
      add :cargo_volume, :decimal
      add :cargo_danger_class, :string, null: false
      add :cargo_special_conditions, :string
      add :insurance_info, :map
      add :customs_info, :map
      add :estimated_delivery_date, :date, null: false
      add :actual_delivery_date, :date, null: false
      add :org_id, references(:organizations), null: false, primary_key: true

      timestamps()
    end

    create index(:orders, [:client_id])
    create index(:orders, [:user_id])
    create index(:orders, [:order_status])
    create index(:orders, [:created_at])
    create index(:orders, [:org_id])

    execute(
      "ALTER TABLE orders ADD CONSTRAINT orders_org_client_fkey FOREIGN KEY (org_id, client_id) REFERENCES clients (org_id, client_id) ON DELETE RESTRICT",
      "ALTER TABLE orders DROP CONSTRAINT orders_org_client_fkey"
    )

    execute(
      "ALTER TABLE orders ADD CONSTRAINT orders_org_user_fkey FOREIGN KEY (org_id, user_id) REFERENCES users (org_id, user_id) ON DELETE RESTRICT",
      "ALTER TABLE orders DROP CONSTRAINT orders_org_user_fkey"
    )
  end
end
