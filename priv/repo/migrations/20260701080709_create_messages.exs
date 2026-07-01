defmodule Copm.Repo.Migrations.CreateMessages do
  use Ecto.Migration

  def change do
    create table(:messages, primary_key: false) do
      add :message_id, :string, primary_key: true
      add :conversation_id, references(:conversations, column: :conversation_id, type: :string, on_delete: :restrict), null: false
      add :message_ts, :utc_datetime, null: false
      add :message_text, :text, null: false
      add :attachments, {:array, :string}
      add :operator_login, :string
      add :ip_address, :string, null: false
      add :related_order_id, references(:orders, column: :order_id, type: :string, on_delete: :nilify_all)

      timestamps()
    end

    create index(:messages, [:conversation_id])
    create index(:messages, [:message_ts])
    create index(:messages, [:related_order_id])
  end
end
