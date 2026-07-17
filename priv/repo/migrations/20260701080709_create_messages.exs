defmodule Copm.Repo.Migrations.CreateMessages do
  use Ecto.Migration

  def change do
    create table(:messages, primary_key: false) do
      add :message_id, :string, primary_key: true
      add :conversation_id, :string, null: false
      add :message_ts, :utc_datetime, null: false
      add :message_text, :text, null: false
      add :attachments, {:array, :string}
      add :operator_login, :string
      add :ip_address, :string, null: false
      add :related_order_id, :string
      add :org_id, references(:organizations), null: false, primary_key: true

      timestamps()
    end

    create index(:messages, [:conversation_id])
    create index(:messages, [:message_ts])
    create index(:messages, [:related_order_id])
    create index(:messages, [:org_id])


    execute(
      "ALTER TABLE messages ADD CONSTRAINT messages_org_conversation_fkey FOREIGN KEY (org_id, conversation_id) REFERENCES conversations (org_id, conversation_id) ON DELETE RESTRICT",
      "ALTER TABLE messages DROP CONSTRAINT messages_org_conversation_fkey"
    )
  end
end
