defmodule CopmWeb.OrgFormLive do
  use CopmWeb, :live_view
  alias Copm.Organizations
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
        max-width: 520px;
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

      .admin-back-link {
        color: rgba(244, 246, 251, 0.6);
        font-size: 14px;
        text-decoration: none;
      }

      .admin-header-actions {
        display: flex;
        align-items: center;
        gap: 16px;
      }

      .admin-logout-link {
        display: inline-flex;
        align-items: center;
        gap: 6px;
        border: 1px solid rgba(255, 255, 255, 0.16);
        border-radius: 10px;
        padding: 8px 14px;
        font-size: 13px;
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

      .admin-form {
        display: flex;
        flex-direction: column;
        gap: 16px;
      }

      .admin-field {
        display: flex;
        flex-direction: column;
        gap: 6px;
      }

      .admin-field label {
        font-size: 11px;
        font-weight: 600;
        text-transform: uppercase;
        letter-spacing: 0.06em;
        color: rgba(244, 246, 251, 0.55);
      }

      .admin-field input {
        appearance: none;
        border: 1px solid rgba(255, 255, 255, 0.16);
        background: rgba(255, 255, 255, 0.06);
        color: #f4f6fb;
        border-radius: 10px;
        padding: 10px 12px;
        font-size: 14px;
        outline: none;
      }

      .admin-field-error {
        font-size: 12px;
        color: #ff9d9d;
      }

      .admin-submit {
        margin-top: 8px;
        border: none;
        border-radius: 10px;
        padding: 13px 16px;
        font-size: 15px;
        font-weight: 600;
        color: #0b1120;
        background: linear-gradient(135deg, #8fb2ff, #6c8cff);
        cursor: pointer;
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

        <div class="admin-header">
          <h1 class="admin-title">Новая организация</h1>
          <div class="admin-header-actions">
            <.link navigate={~p"/admin/orgs"} class="admin-back-link">← К списку</.link>
            <.link href={~p"/logout"} class="admin-logout-link">Выйти</.link>
          </div>
        </div>

        <div class="admin-panel">
          <.form for={%{}} as={:organization} phx-submit="save" class="admin-form">
            <div class="admin-field">
              <label for="org_name">Название</label>
              <input type="text" id="org_name" name="organization[org_name]" value={@org.org_name} required />
              <span :if={msg = error_for(@errors, :org_name)} class="admin-field-error">{msg}</span>
            </div>

            <button class="admin-submit" type="submit">Создать</button>
          </.form>
        </div>
      </div>
    </div>
    """
  end
end
