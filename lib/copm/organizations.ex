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
  def delete_organization(org) do
    org
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.foreign_key_constraint(:id, name: :operators_org_id_fkey, message: "нельзя удалить - есть привязанные операторы")
    |> Repo.delete()
  end
end
