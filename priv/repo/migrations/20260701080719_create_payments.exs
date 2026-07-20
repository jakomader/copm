defmodule Copm.Repo.Migrations.CreatePayments do
  use Ecto.Migration

  def change do
    create table(:payments, primary_key: false) do
      add :payment_id, :string, primary_key: true
      add :order_id, :string, null: false
      add :client_id, :string, null: false
      add :user_id, :string, null: false
      add :payment_ts, :string, null: false
      add :payment_type, :string, null: false
      add :payment_method, :string, null: false
      add :amount, :decimal, null: false
      add :currency, :string, null: false
      add :invoice_number, :string, null: false
      add :from_bank_info, :map, null: false
      add :to_bank_info, :map, null: false
      add :payment_status, :string, null: false
      add :external_payment_id, :string
      add :session_id, :string, null: false
      add :ip_address, :string, null: false
      add :org_id, references(:organizations), null: false, primary_key: true

      timestamps()
    end

    create index(:payments, [:order_id])
    create index(:payments, [:client_id])
    create index(:payments, [:user_id])
    create index(:payments, [:payment_ts])
    create index(:payments, [:session_id])
    create index(:payments, [:org_id])


  end
end
