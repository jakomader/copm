defmodule CopmWeb.OperatorFormLive do
  use CopmWeb, :live_view
  alias Copm.Auth
  import CopmWeb.Components.AdminLayout
  on_mount {CopmWeb.RequireAdminHook, :default}

  def mount(params, _session, socket) do
    socket =
    case socket.assigns.live_action do
      :new ->
        role = params["role"] || "admin"
        socket
        |> assign(operator: %Copm.Schemas.Operators{role: role}, errors: %{})
      :edit ->
        id = String.to_integer(params["id"])
        if id == socket.assigns.current_operator.id do
          push_navigate(socket, to: ~p"/admin/users/admins")
        else
          case Copm.Repo.get(Copm.Schemas.Operators, id) do
            nil -> push_navigate(socket, to: ~p"/logout")
            operator -> socket |> assign(operator: operator, errors: %{})
          end
        end
    end
    socket = assign(socket, orgs: Copm.Organizations.list_organizations())
    {:ok, socket}
  end

  def handle_event("role_changed", %{"operator" => params}, socket) do
    {:noreply, assign(socket, operator: %{socket.assigns.operator | role: params["role"]})}
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
        {:ok, operator} ->
          socket
          |> put_flash(:info, "Пользователь успешно сохранён")
          |> push_navigate(to: section_path(operator.role))

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

  defp section_for_role("admin"), do: :admins
  defp section_for_role("data_provider"), do: :suppliers
  defp section_for_role("queries_only"), do: :consumers
  defp section_for_role(_), do: :admins

  defp section_path("admin"), do: ~p"/admin/users/admins"
  defp section_path("data_provider"), do: ~p"/admin/users/suppliers"
  defp section_path("queries_only"), do: ~p"/admin/users/consumers"
  defp section_path(_), do: ~p"/admin/users/admins"

  def render(assigns) do
    ~H"""
    <.admin_shell
      active={section_for_role(@operator.role)}
      current_operator={@current_operator}
      title={if @live_action == :new, do: "Новый пользователь", else: "Редактирование пользователя"}
      flash={@flash}
    >
      <:actions>
        <.link navigate={section_path(@operator.role)} class="adm-btn adm-btn-ghost">← К списку</.link>
      </:actions>

      <div class="adm-form-card">
        <.form for={%{}} as={:operator} phx-submit="save" class="adm-form">
          <div class="adm-field">
            <label for="login">Логин</label>
            <input type="text" id="login" name="operator[login]" value={@operator.login} required />
            <span :if={msg = error_for(@errors, :login)} class="adm-field-error">{msg}</span>
          </div>

          <div class="adm-field">
            <label for="name">Имя</label>
            <input type="text" id="name" name="operator[name]" value={@operator.name} required />
            <span :if={msg = error_for(@errors, :name)} class="adm-field-error">{msg}</span>
          </div>

          <div class="adm-field">
            <label for="purpose">Назначение</label>
            <input type="text" id="purpose" name="operator[purpose]" value={@operator.purpose} />
            <span :if={msg = error_for(@errors, :purpose)} class="adm-field-error">{msg}</span>
          </div>

          <div class="adm-field">
            <label for="role">Роль</label>
            <select id="role" name="operator[role]" phx-change="role_changed">
              <option value="admin" selected={@operator.role == "admin"}>Администратор</option>
              <option value="data_provider" selected={@operator.role == "data_provider"}>Поставщик</option>
              <option value="queries_only" selected={@operator.role == "queries_only"}>Потребитель</option>
            </select>
            <span :if={msg = error_for(@errors, :role)} class="adm-field-error">{msg}</span>
          </div>

          <div :if={@operator.role == "data_provider"} class="adm-field">
            <label for="org_id">Организация</label>
            <select id="org_id" name="operator[org_id]">
              <option
                :for={org <- @orgs}
                value={org.id}
                selected={@operator.org_id == org.id}
              >{org.org_name}</option>
            </select>
            <span :if={msg = error_for(@errors, :org_id)} class="adm-field-error">{msg}</span>
          </div>

          <div :if={@live_action == :edit} class="adm-field">
            <label for="status">Статус</label>
            <select id="status" name="operator[status]">
              <option value="active" selected={@operator.status == "active"}>active</option>
              <option value="blocked" selected={@operator.status == "blocked"}>blocked</option>
            </select>
            <span :if={msg = error_for(@errors, :status)} class="adm-field-error">{msg}</span>
          </div>

          <div class="adm-field">
            <label for="password">Пароль</label>
            <input type="password" id="password" name="operator[password]" placeholder={if @live_action == :edit, do: "оставьте пустым, чтобы не менять", else: ""} required={@live_action == :new} />
            <span :if={msg = error_for(@errors, :password)} class="adm-field-error">{msg}</span>
            <span :if={@live_action == :edit} class="adm-hint">Оставьте пустым, если не хотите менять пароль</span>
          </div>

          <button class="adm-btn adm-btn-primary" type="submit">
            {if @live_action == :new, do: "Создать", else: "Сохранить"}
          </button>
        </.form>
      </div>
    </.admin_shell>
    """
  end
end
