defmodule CopmWeb.OrgLive do
  use CopmWeb, :live_view
  alias Copm.Organizations
  on_mount {CopmWeb.RequireAdminHook, :default}

  def mount(_params, _session, socket) do
    socket = assign(socket, orgs: Organizations.list_organizations())
    {:ok, socket}
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
          |> assign(orgs: Organizations.list_organizations())

        {:error, _changeset} ->
          put_flash(socket, :error, "Нельзя удалить — есть привязанные операторы")
      end

    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <style>
      body {
        margin: 0;
        font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
      }

      .admin-page {
        min-height: 100vh;
        background: radial-gradient(circle at top, #1e2a4a 0%, #0b1120 65%);
        padding: 32px 16px;
        color: #f4f6fb;
      }

      .admin-shell {
        max-width: 720px;
        margin: 0 auto;
      }

      .admin-header {
        display: flex;
        justify-content: space-between;
        align-items: center;
        margin-bottom: 24px;
        flex-wrap: wrap;
        gap: 12px;
      }

      .admin-title {
        margin: 0;
        font-size: 24px;
        font-weight: 700;
        letter-spacing: 0.02em;
      }

      .admin-create-link {
        display: inline-flex;
        align-items: center;
        gap: 6px;
        border: none;
        border-radius: 10px;
        padding: 11px 18px;
        font-size: 14px;
        font-weight: 600;
        color: #0b1120;
        background: linear-gradient(135deg, #8fb2ff, #6c8cff);
        text-decoration: none;
      }

      .admin-header-actions {
        display: flex;
        align-items: center;
        gap: 10px;
      }

      .admin-logout-link {
        display: inline-flex;
        align-items: center;
        gap: 6px;
        border: 1px solid rgba(255, 255, 255, 0.16);
        border-radius: 10px;
        padding: 10px 16px;
        font-size: 14px;
        font-weight: 600;
        color: rgba(244, 246, 251, 0.7);
        background: rgba(255, 255, 255, 0.04);
        text-decoration: none;
      }

      .admin-panel {
        background: rgba(255, 255, 255, 0.06);
        border: 1px solid rgba(255, 255, 255, 0.12);
        border-radius: 16px;
        padding: 24px;
        box-shadow: 0 20px 60px rgba(0, 0, 0, 0.45);
        backdrop-filter: blur(14px);
      }

      .admin-table {
        width: 100%;
        border-collapse: collapse;
        font-size: 14px;
      }

      .admin-table th {
        text-align: left;
        font-size: 11px;
        text-transform: uppercase;
        letter-spacing: 0.06em;
        color: rgba(244, 246, 251, 0.5);
        padding: 10px 12px;
        border-bottom: 1px solid rgba(255, 255, 255, 0.12);
      }

      .admin-table td {
        padding: 12px;
        border-bottom: 1px solid rgba(255, 255, 255, 0.08);
        vertical-align: middle;
      }

      .admin-row-actions {
        display: flex;
        gap: 8px;
        justify-content: flex-end;
      }

      .admin-action-btn {
        border: 1px solid rgba(255, 255, 255, 0.16);
        background: rgba(255, 255, 255, 0.06);
        color: #f4f6fb;
        border-radius: 8px;
        padding: 6px 12px;
        font-size: 13px;
        cursor: pointer;
        text-decoration: none;
      }

      .admin-action-btn.danger:hover {
        background: rgba(255, 90, 90, 0.15);
        border-color: rgba(255, 90, 90, 0.5);
      }
      .admin-back-link {
        color: rgba(244, 246, 251, 0.6);
        font-size: 14px;
        text-decoration: none;
      }

      .admin-back-link:hover {
        color: #f4f6fb;
      }
      .admin-empty {
        text-align: center;
        padding: 32px;
        color: rgba(244, 246, 251, 0.5);
      }

      .admin-flash {
        margin: 0 0 20px;
        padding: 12px 16px;
        border-radius: 10px;
        font-size: 14px;
      }

      .admin-flash.error {
        background: rgba(255, 90, 90, 0.12);
        border: 1px solid rgba(255, 90, 90, 0.35);
        color: #ff9d9d;
      }

      .admin-flash.info {
        background: rgba(108, 140, 255, 0.12);
        border: 1px solid rgba(108, 140, 255, 0.35);
        color: #8fb2ff;
      }
    </style>

    <div class="admin-page">
      <div class="admin-shell">
        <p
          :if={msg = Phoenix.Flash.get(@flash, :error)}
          id="flash-error"
          phx-hook="AutoDismissFlash"
          phx-click="lv:clear-flash"
          phx-value-key="error"
          class="admin-flash error"
        >{msg}</p>
        <p
          :if={msg = Phoenix.Flash.get(@flash, :info)}
          id="flash-info"
          phx-hook="AutoDismissFlash"
          phx-click="lv:clear-flash"
          phx-value-key="info"
          class="admin-flash info"
        >{msg}</p>

        <div class="admin-header">
          <h1 class="admin-title">Организации</h1>
          <div class="admin-header-actions">
            <.link navigate={~p"/admin/operators"} class="admin-back-link">← К операторам</.link>
            <.link navigate={~p"/admin/orgs/new"} class="admin-create-link">+ Создать организацию</.link>
            <.link href={~p"/logout"} class="admin-logout-link">Выйти</.link>
          </div>
        </div>

        <div class="admin-panel">
          <table class="admin-table">
            <thead>
              <tr>
                <th>ID</th>
                <th>Название</th>
                <th>Добавлена</th>
                <th></th>
              </tr>
            </thead>
            <tbody>
              <tr :for={org <- @orgs}>
                <td>{org.id}</td>
                <td>{org.org_name}</td>
                <td>{Calendar.strftime(org.inserted_at, "%d.%m.%Y")}</td>
                <td>
                  <div class="admin-row-actions">
                    <button
                      class="admin-action-btn danger"
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

          <p :if={@orgs == []} class="admin-empty">Организации не найдены</p>
        </div>
      </div>
    </div>
    """
  end
end
