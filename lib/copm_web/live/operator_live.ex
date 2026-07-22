defmodule CopmWeb.OperatorLive do
  use CopmWeb, :live_view
  alias Copm.Auth
  import CopmWeb.Components.AdminLayout
  on_mount {CopmWeb.RequireAdminHook, :default}

  def mount(_params, _session, socket) do
    filters = %{"login" => "", "name" => "", "status" => "", "date_from" => "", "date_to" => ""}

    socket =
      socket
      |> assign(filters: filters)
      |> assign(operators: Auth.list_operators(build_filters(filters, socket.assigns.live_action)))

    {:ok, socket}
  end

  def handle_event("filter", %{"filters" => raw}, socket) do
    operators = Auth.list_operators(build_filters(raw, socket.assigns.live_action))

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
          filters = build_filters(socket.assigns.filters, socket.assigns.live_action)
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
          filters = build_filters(socket.assigns.filters, socket.assigns.live_action)
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

  defp build_filters(raw, live_action) do
    %{
      login: blank_to_nil(raw["login"]),
      name: blank_to_nil(raw["name"]),
      role: role_for(live_action),
      status: blank_to_nil(raw["status"]),
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

  defp role_for(:admins), do: "admin"
  defp role_for(:suppliers), do: "data_provider"
  defp role_for(:consumers), do: "queries_only"

  defp section_title(:admins), do: "Администраторы"
  defp section_title(:suppliers), do: "Поставщики"
  defp section_title(:consumers), do: "Потребители"

  def render(assigns) do
    ~H"""
    <.admin_shell
      active={@live_action}
      current_operator={@current_operator}
      title={section_title(@live_action)}
      count={length(@operators)}
      flash={@flash}
    >
      <:actions>
        <.link navigate={~p"/admin/users/new?role=#{role_for(@live_action)}"} class="adm-icon-btn" title="Добавить пользователя">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 5v14M5 12h14" stroke-linecap="round" /></svg>
        </.link>
      </:actions>

      <div class="adm-table-wrap">
          <form phx-change="filter">
            <table class="adm-table">
              <thead>
                <tr>
                  <th>Логин</th>
                  <th>Имя</th>
                  <th>Статус</th>
                  <th :if={@live_action == :suppliers}>Организация</th>
                  <th>Добавлен</th>
                  <th></th>
                </tr>
                <tr class="adm-filter-row">
                  <th>
                    <label class="adm-search">
                      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="11" cy="11" r="7" /><path d="M21 21l-4.3-4.3" stroke-linecap="round" /></svg>
                      <input type="text" name="filters[login]" value={@filters["login"]} placeholder="Поиск" />
                    </label>
                  </th>
                  <th>
                    <label class="adm-search">
                      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="11" cy="11" r="7" /><path d="M21 21l-4.3-4.3" stroke-linecap="round" /></svg>
                      <input type="text" name="filters[name]" value={@filters["name"]} placeholder="Поиск" />
                    </label>
                  </th>
                  <th>
                    <label class="adm-search">
                      <select name="filters[status]">
                        <option value="" selected={@filters["status"] in [nil, ""]}>Все</option>
                        <option value="active" selected={@filters["status"] == "active"}>active</option>
                        <option value="blocked" selected={@filters["status"] == "blocked"}>blocked</option>
                      </select>
                    </label>
                  </th>
                  <th :if={@live_action == :suppliers}></th>
                  <th>
                    <div style="display:flex; gap:6px;">
                      <label class="adm-search"><input type="date" name="filters[date_from]" value={@filters["date_from"]} /></label>
                      <label class="adm-search"><input type="date" name="filters[date_to]" value={@filters["date_to"]} /></label>
                    </div>
                  </th>
                  <th></th>
                </tr>
              </thead>
              <tbody>
                <tr :for={operator <- @operators}>
                  <td>{operator.login}</td>
                  <td>{operator.name}</td>
                  <td><span class={"adm-badge #{operator.status}"}>{operator.status}</span></td>
                  <td :if={@live_action == :suppliers}>{if operator.organization, do: operator.organization.org_name, else: "-"}</td>
                  <td>{Calendar.strftime(operator.inserted_at, "%d.%m.%Y")}</td>
                  <td class="adm-col-actions">
                    <div class="adm-row-actions">
                      <.link navigate={~p"/admin/users/#{operator.id}/edit"} class="adm-btn adm-btn-ghost adm-btn-sm">
                        Изменить
                      </.link>
                      <button
                        class="adm-btn adm-btn-ghost adm-btn-sm"
                        phx-click="block"
                        phx-value-id={operator.id}
                        disabled={operator.status == "blocked"}
                      >
                        Заблокировать
                      </button>
                      <button
                        class="adm-btn adm-btn-danger adm-btn-sm"
                        phx-click="delete"
                        phx-value-id={operator.id}
                        data-confirm="Удалить пользователя безвозвратно?"
                      >
                        Удалить
                      </button>
                    </div>
                  </td>
                </tr>
              </tbody>
            </table>
          </form>

          <p :if={@operators == []} class="adm-empty">Пользователи не найдены</p>
        </div>
    </.admin_shell>
    """
  end
end
