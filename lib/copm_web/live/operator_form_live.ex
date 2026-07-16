defmodule CopmWeb.OperatorFormLive do
  use CopmWeb, :live_view
  alias Copm.Auth
  on_mount {CopmWeb.RequireAdminHook, :default}

  def mount(params, _session, socket) do
    socket =
    case socket.assigns.live_action do
      :new ->
        socket
        |> assign(operator: %Copm.Schemas.Operators{}, errors: %{})
      :edit ->
        id = String.to_integer(params["id"])
        if id == socket.assigns.current_operator.id do
          push_navigate(socket, to: ~p"/admin/operators")
        else
          case Copm.Repo.get(Copm.Schemas.Operators, id) do
            nil -> push_navigate(socket, to: ~p"/logout")
            operator -> socket |> assign(operator: operator, errors: %{})
          end
        end
    end
    {:ok, socket}
  end

  def handle_event("save", %{"operator" => params}, socket) do
    params = if blank?(params["password"]), do: Map.delete(params, "password"), else: params
    socket = if Copm.Repo.get(Copm.Schemas.Operators, socket.assigns.current_operator.id).status == "blocked" do
        redirect(socket, to: ~p"/logout")
    else
    result =
      case socket.assigns.live_action do
        :new -> Auth.create_operator(params)
        :edit -> Auth.update_user(socket.assigns.operator, params)
      end

      case result do
        {:ok, _operator} ->
          socket
          |> put_flash(:info, "Оператор успешно сохранён")
          |> push_navigate(to: ~p"/admin/operators")

        {:error, changeset} ->
          errors =
            Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
              Enum.reduce(opts, msg, fn {key, value}, acc ->
                String.replace(acc, "%{#{key}}", to_string(value))
              end)
            end)

          assign(socket, errors: errors)
      end
    end
    {:noreply, socket}
  end

  defp blank?(nil), do: true
  defp blank?(""), do: true
  defp blank?(_), do: false

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

      .admin-back-link:hover {
        color: #f4f6fb;
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
        transition: border-color 0.15s ease, background 0.15s ease, box-shadow 0.15s ease;
      }

      .admin-field select option {
        color: #0b1120;
        background: #ffffff;
      }

      .admin-field input:focus,
      .admin-field select:focus {
        border-color: #6c8cff;
        background: rgba(108, 140, 255, 0.1);
        box-shadow: 0 0 0 3px rgba(108, 140, 255, 0.25);
      }

      .admin-field-error {
        font-size: 12px;
        color: #ff9d9d;
      }

      .admin-hint {
        font-size: 12px;
        color: rgba(244, 246, 251, 0.4);
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
        transition: filter 0.15s ease, box-shadow 0.15s ease;
      }

      .admin-submit:hover {
        filter: brightness(1.05);
        box-shadow: 0 10px 24px rgba(108, 140, 255, 0.35);
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
          <h1 class="admin-title">{if @live_action == :new, do: "Новый оператор", else: "Редактирование оператора"}</h1>
          <div class="admin-header-actions">
            <.link navigate={~p"/admin/operators"} class="admin-back-link">← К списку</.link>
            <.link href={~p"/logout"} class="admin-logout-link">Выйти</.link>
          </div>
        </div>

        <div class="admin-panel">
          <.form for={%{}} as={:operator} phx-submit="save" class="admin-form">
            <div class="admin-field">
              <label for="login">Логин</label>
              <input type="text" id="login" name="operator[login]" value={@operator.login} required />
              <span :if={msg = error_for(@errors, :login)} class="admin-field-error">{msg}</span>
            </div>

            <div class="admin-field">
              <label for="name">Имя</label>
              <input type="text" id="name" name="operator[name]" value={@operator.name} required />
              <span :if={msg = error_for(@errors, :name)} class="admin-field-error">{msg}</span>
            </div>

            <div class="admin-field">
              <label for="purpose">Назначение</label>
              <input type="text" id="purpose" name="operator[purpose]" value={@operator.purpose} />
              <span :if={msg = error_for(@errors, :purpose)} class="admin-field-error">{msg}</span>
            </div>

            <div class="admin-field">
              <label for="role">Роль</label>
              <select id="role" name="operator[role]">
                <option value="admin" selected={@operator.role == "admin"}>admin</option>
                <option value="data_provider" selected={@operator.role == "data_provider"}>data_provider</option>
                <option value="queries_only" selected={@operator.role == "queries_only"}>queries_only</option>
              </select>
              <span :if={msg = error_for(@errors, :role)} class="admin-field-error">{msg}</span>
            </div>

            <div :if={@live_action == :edit} class="admin-field">
              <label for="status">Статус</label>
              <select id="status" name="operator[status]">
                <option value="active" selected={@operator.status == "active"}>active</option>
                <option value="blocked" selected={@operator.status == "blocked"}>blocked</option>
              </select>
              <span :if={msg = error_for(@errors, :status)} class="admin-field-error">{msg}</span>
            </div>

            <div class="admin-field">
              <label for="password">Пароль</label>
              <input type="password" id="password" name="operator[password]" placeholder={if @live_action == :edit, do: "оставьте пустым, чтобы не менять", else: ""} required={@live_action == :new} />
              <span :if={msg = error_for(@errors, :password)} class="admin-field-error">{msg}</span>
              <span :if={@live_action == :edit} class="admin-hint">Оставьте пустым, если не хотите менять пароль</span>
            </div>

            <button class="admin-submit" type="submit">
              {if @live_action == :new, do: "Создать", else: "Сохранить"}
            </button>
          </.form>
        </div>
      </div>
    </div>
    """
  end
end
