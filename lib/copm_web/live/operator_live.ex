defmodule CopmWeb.OperatorLive do
  use CopmWeb, :live_view
  alias Copm.Auth
  on_mount {CopmWeb.RequireAdminHook, :default}

  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(filters: %{login: "", role: "", date_from: "", date_to: ""})
      |> assign(operators: Auth.list_operators(%{}))

    {:ok, socket}
  end

  def handle_event("filter", %{"filters" => raw}, socket) do
    operators = Auth.list_operators(raw |> manage_filters())

    socket =
      socket
      |> assign(filters: raw)
      |> assign(operators: operators)

    {:noreply, socket}
  end

  def handle_event("block", %{"id" => id}, socket) do
    socket =
    if String.to_integer(id) == socket.assigns.current_operator.id do
      put_flash(socket, :error, "Блокировка самого себя не разрешена")
    else
      if Copm.Repo.get(Copm.Schemas.Operators, socket.assigns.current_operator.id).status == "active" do
        id = String.to_integer(id)
        case Copm.Repo.get(Copm.Schemas.Operators, id) do
          nil -> put_flash(socket, :error, "Operator was not found")
          operator ->
            Auth.block_user(operator)
          filters = manage_filters(socket.assigns.filters)
          socket
          |> put_flash(:info, "Оператор был успешно заблокирован")
          |> assign(operators: Auth.list_operators(filters))
        end
      else
        redirect(socket, to: ~p"/logout")
      end
    end
    {:noreply, socket}
  end
  def handle_event("delete", %{"id" => id}, socket) do
    socket =
    if String.to_integer(id) == socket.assigns.current_operator.id do
      put_flash(socket, :error, "Удаление самого себя не разрешено")
    else
      if Copm.Repo.get(Copm.Schemas.Operators, socket.assigns.current_operator.id).status == "active" do
        id = String.to_integer(id)
        case Copm.Repo.get(Copm.Schemas.Operators, id) do
          nil -> put_flash(socket, :error, "Operator was not found")
          operator ->
            Auth.delete_user(operator)
          filters = manage_filters(socket.assigns.filters)
          socket
          |> put_flash(:info, "Оператор был успешно удалён")
          |> assign(operators: Auth.list_operators(filters))
        end
      else
        redirect(socket, to: ~p"/logout")
      end
    end
    {:noreply, socket}
  end

  defp manage_filters(raw) do
    %{
      login: blank_to_nil(raw["login"]),
      role: blank_to_nil(raw["role"]),
      date: %{
        from: parse_date(raw["date_from"]),
        to: parse_date(raw["date_to"])
      }
    }
  end
  defp blank_to_nil(nil), do: nil
  defp blank_to_nil(""), do: nil
  defp blank_to_nil(v), do: v

  defp parse_date(nil), do: nil
  defp parse_date(""), do: nil

  defp parse_date(v) do
    case Date.from_iso8601(v) do
      {:ok, date} -> DateTime.new!(date, ~T[00:00:00])
      _ -> nil
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
        max-width: 1080px;
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
        transition: filter 0.15s ease, box-shadow 0.15s ease;
      }

      .admin-create-link:hover {
        filter: brightness(1.05);
        box-shadow: 0 10px 24px rgba(108, 140, 255, 0.35);
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
        transition: background 0.15s ease, border-color 0.15s ease, color 0.15s ease;
      }

      .admin-logout-link:hover {
        background: rgba(255, 90, 90, 0.1);
        border-color: rgba(255, 90, 90, 0.4);
        color: #ff9d9d;
      }

      .admin-panel {
        background: rgba(255, 255, 255, 0.06);
        border: 1px solid rgba(255, 255, 255, 0.12);
        border-radius: 16px;
        padding: 24px;
        box-shadow: 0 20px 60px rgba(0, 0, 0, 0.45);
        backdrop-filter: blur(14px);
      }

      .admin-filters {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
        gap: 14px;
        margin-bottom: 20px;
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

      .admin-field input,
      .admin-field select {
        appearance: none;
        border: 1px solid rgba(255, 255, 255, 0.16);
        background: rgba(255, 255, 255, 0.06);
        color: #f4f6fb;
        border-radius: 10px;
        padding: 10px 12px;
        font-size: 14px;
        outline: none;
      }

      .admin-field select option {
        color: #0b1120;
        background: #ffffff;
        transition: border-color 0.15s ease, background 0.15s ease, box-shadow 0.15s ease;
      }

      .admin-field input:focus,
      .admin-field select:focus {
        border-color: #6c8cff;
        background: rgba(108, 140, 255, 0.1);
        box-shadow: 0 0 0 3px rgba(108, 140, 255, 0.25);
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

      .admin-badge {
        display: inline-block;
        padding: 3px 10px;
        border-radius: 999px;
        font-size: 12px;
        font-weight: 600;
      }

      .admin-badge.active {
        background: rgba(90, 220, 140, 0.15);
        color: #7ef0ab;
      }

      .admin-badge.blocked {
        background: rgba(255, 90, 90, 0.15);
        color: #ff9d9d;
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
        transition: background 0.15s ease, border-color 0.15s ease;
      }

      .admin-action-btn:hover {
        background: rgba(108, 140, 255, 0.15);
        border-color: #6c8cff;
      }

      .admin-action-btn.danger:hover {
        background: rgba(255, 90, 90, 0.15);
        border-color: rgba(255, 90, 90, 0.5);
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
          <h1 class="admin-title">Операторы</h1>
          <div class="admin-header-actions">
            <.link navigate={~p"/admin/operators/new"} class="admin-create-link">+ Создать оператора</.link>
            <.link href={~p"/logout"} class="admin-logout-link">Выйти</.link>
          </div>
        </div>

        <div class="admin-panel">
          <form phx-change="filter">
            <div class="admin-filters">
              <div class="admin-field">
                <label for="filter_login">Логин</label>
                <input type="text" id="filter_login" name="filters[login]" value={@filters["login"]} placeholder="Поиск по логину" />
              </div>
              <div class="admin-field">
                <label for="filter_role">Роль</label>
                <select id="filter_role" name="filters[role]">
                  <option value="" selected={@filters["role"] in [nil, ""]}>Все роли</option>
                  <option value="admin" selected={@filters["role"] == "admin"}>admin</option>
                  <option value="data_provider" selected={@filters["role"] == "data_provider"}>data_provider</option>
                  <option value="queries_only" selected={@filters["role"] == "queries_only"}>queries_only</option>
                </select>
              </div>
              <div class="admin-field">
                <label for="filter_date_from">Добавлен с</label>
                <input type="date" id="filter_date_from" name="filters[date_from]" value={@filters["date_from"]} />
              </div>
              <div class="admin-field">
                <label for="filter_date_to">Добавлен по</label>
                <input type="date" id="filter_date_to" name="filters[date_to]" value={@filters["date_to"]} />
              </div>
            </div>
          </form>

          <table class="admin-table">
            <thead>
              <tr>
                <th>ID</th>
                <th>Логин</th>
                <th>Имя</th>
                <th>Роль</th>
                <th>Статус</th>
                <th>Добавлен</th>
                <th></th>
              </tr>
            </thead>
            <tbody>
              <tr :for={operator <- @operators}>
                <td>{operator.id}</td>
                <td>{operator.login}</td>
                <td>{operator.name}</td>
                <td>{operator.role}</td>
                <td>
                  <span class={"admin-badge #{operator.status}"}>{operator.status}</span>
                </td>
                <td>{Calendar.strftime(operator.inserted_at, "%d.%m.%Y")}</td>
                <td>
                  <div class="admin-row-actions">
                    <.link navigate={~p"/admin/operators/#{operator.id}/edit"} class="admin-action-btn">
                      Изменить
                    </.link>
                    <button
                      class="admin-action-btn"
                      phx-click="block"
                      phx-value-id={operator.id}
                      disabled={operator.status == "blocked"}
                    >
                      Заблокировать
                    </button>
                    <button
                      class="admin-action-btn danger"
                      phx-click="delete"
                      phx-value-id={operator.id}
                      data-confirm="Удалить оператора безвозвратно?"
                    >
                      Удалить
                    </button>
                  </div>
                </td>
              </tr>
            </tbody>
          </table>

          <p :if={@operators == []} class="admin-empty">Операторы не найдены</p>
        </div>
      </div>
    </div>
    """
  end
end
