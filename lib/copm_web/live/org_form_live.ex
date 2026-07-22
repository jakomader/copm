defmodule CopmWeb.OrgFormLive do
  use CopmWeb, :live_view
  alias Copm.Organizations
  import CopmWeb.Components.AdminLayout
  on_mount {CopmWeb.RequireAdminHook, :default}

  def mount(_params, _session, socket) do
    {:ok, assign(socket, org: %Copm.Schemas.Organizations{}, errors: %{})}
  end

  def handle_event("save", %{"organization" => params}, socket) do
    case Organizations.create_organization(params) do
      {:ok, _org} ->
        {:noreply,
         socket
         |> put_flash(:info, "Организация успешно создана")
         |> push_navigate(to: ~p"/admin/orgs")}

      {:error, changeset} ->
        errors =
          Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
            Enum.reduce(opts, msg, fn {key, value}, acc ->
              String.replace(acc, "%{#{key}}", to_string(value))
            end)
          end)

        {:noreply, assign(socket, errors: errors)}
    end
  end

  defp error_for(errors, field) do
    case Map.get(errors, field) do
      nil -> nil
      [msg | _] -> msg
    end
  end

  def render(assigns) do
    ~H"""
    <.admin_shell active={:orgs} current_operator={@current_operator} title="Новая организация" flash={@flash}>
      <:actions>
        <.link navigate={~p"/admin/orgs"} class="adm-btn adm-btn-ghost">← К списку</.link>
      </:actions>

      <div class="adm-form-card">
        <.form for={%{}} as={:organization} phx-submit="save" class="adm-form">
          <div class="adm-field">
            <label for="org_name">Название</label>
            <input type="text" id="org_name" name="organization[org_name]" value={@org.org_name} required />
            <span :if={msg = error_for(@errors, :org_name)} class="adm-field-error">{msg}</span>
          </div>

          <button class="adm-btn adm-btn-primary" type="submit">Создать</button>
        </.form>
      </div>
    </.admin_shell>
    """
  end
end
