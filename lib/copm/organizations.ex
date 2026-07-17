defmodule Copm.Organizations do
  alias Copm.Repo

  def list_organizations() do
    Repo.all(Copm.Schemas.Organizations)
  end
  def create_organization(name) do
    %Copm.Schemas.Organizations{}
    |> Copm.Schemas.Organizations.changeset(name)
    |> Copm.Repo.insert()
  end
  @referencing_tables ~w(
    operators clients client_relations client_contacts users auth_events
    orders tracking_events conversations messages ipdr_records payments
  )a

  def delete_organization(org) do
    Enum.reduce(@referencing_tables, Ecto.Changeset.change(org), fn table, changeset ->
      Ecto.Changeset.foreign_key_constraint(changeset, :id,
        name: :"#{table}_org_id_fkey",
        message: "нельзя удалить - есть привязанные данные (#{table})"
      )
    end)
    |> Repo.delete()
  end
end
