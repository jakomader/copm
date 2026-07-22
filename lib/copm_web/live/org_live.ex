defmodule CopmWeb.OrgLive do
  use CopmWeb, :live_view
  alias Copm.Organizations
  import CopmWeb.Components.AdminLayout
  on_mount {CopmWeb.RequireAdminHook, :default}

  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(search: "")
      |> assign(all_orgs: Organizations.list_organizations())
      |> filter_orgs()

    {:ok, socket}
  end

  def handle_event("filter", %{"search" => search}, socket) do
    socket =
      socket
      |> assign(search: search)
      |> filter_orgs()

    {:noreply, socket}
  end

  def handle_event("delete", %{"id" => id}, socket) do
    org = Copm.Repo.get(Copm.Schemas.Organizations, String.to_integer(id))

    socket =
      case org && Organizations.delete_organization(org) do
        nil ->
          put_flash(socket, :error, "Организация не найдена")

        {:ok, _} ->
          socket
          |> put_flash(:info, "Организация удалена")
          |> assign(all_orgs: Organizations.list_organizations())
          |> filter_orgs()

        {:error, _changeset} ->
          put_flash(socket, :error, "Нельзя удалить - есть привязанные операторы")
      end

    {:noreply, socket}
  end

  defp filter_orgs(socket) do
    search = String.trim(socket.assigns.search)

    orgs =
      if search == "" do
        socket.assigns.all_orgs
      else
        needle = String.downcase(search)
        Enum.filter(socket.assigns.all_orgs, fn org ->
          String.contains?(String.downcase(org.org_name || ""), needle)
        end)
      end

    assign(socket, orgs: orgs)
  end

  def render(assigns) do
    ~H"""
    <.admin_shell active={:orgs} current_operator={@current_operator} title="Организации" count={length(@orgs)} flash={@flash}>
      <:actions>
        <.link navigate={~p"/admin/orgs/new"} class="adm-icon-btn" title="Добавить организацию">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 5v14M5 12h14" stroke-linecap="round" /></svg>
        </.link>
      </:actions>

      <div class="adm-table-wrap">
          <form phx-change="filter">
            <table class="adm-table">
              <thead>
                <tr>
                  <th>ID</th>
                  <th>Название</th>
                  <th>Добавлена</th>
                  <th></th>
                </tr>
                <tr class="adm-filter-row">
                  <th></th>
                  <th>
                    <label class="adm-search">
                      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="11" cy="11" r="7" /><path d="M21 21l-4.3-4.3" stroke-linecap="round" /></svg>
                      <input type="text" name="search" value={@search} placeholder="Поиск" />
                    </label>
                  </th>
                  <th></th>
                  <th></th>
                </tr>
              </thead>
              <tbody>
                <tr :for={org <- @orgs}>
                  <td>{org.id}</td>
                  <td>{org.org_name}</td>
                  <td>{Calendar.strftime(org.inserted_at, "%d.%m.%Y")}</td>
                  <td class="adm-col-actions">
                    <div class="adm-row-actions">
                      <button
                        class="adm-btn adm-btn-danger adm-btn-sm"
                        phx-click="delete"
                        phx-value-id={org.id}
                        data-confirm="Удалить организацию безвозвратно?"
                      >
                        Удалить
                      </button>
                    </div>
                  </td>
                </tr>
              </tbody>
            </table>
          </form>

          <p :if={@orgs == []} class="adm-empty">Организации не найдены</p>
        </div>
    </.admin_shell>
    """
  end
end
