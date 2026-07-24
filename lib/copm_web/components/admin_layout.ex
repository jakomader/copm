defmodule CopmWeb.Components.AdminLayout do
  @moduledoc """
  Shared sidebar/topbar shell for the authenticated admin panel.

  Every admin LiveView renders its content through `admin_shell/1` so the
  navigation, page chrome and base styling stay in one place. Theme (dark by
  default, switchable to light) is controlled by `data-theme` on `<html>`,
  set/persisted globally in the root layout (`window.copmToggleTheme()`).
  """
  use Phoenix.Component
  use CopmWeb, :verified_routes

  @doc """
  Wraps admin page content with the sidebar navigation and topbar.

  `active` selects which nav entry is highlighted: `:admins`, `:suppliers`,
  `:consumers` or `:orgs`.
  """
  attr :active, :atom, required: true
  attr :current_operator, :any, default: nil
  attr :title, :string, required: true
  attr :count, :integer, default: nil
  attr :flash, :map, default: %{}

  slot :actions
  slot :inner_block, required: true

  def admin_shell(assigns) do
    users_section? = assigns.active in [:admins, :suppliers, :consumers]
    assigns = assign(assigns, :users_section?, users_section?)

    ~H"""
    <style>
      body {
        margin: 0;
        font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
      }

      :root[data-theme="dark"] {
        --adm-bg: #0a0b0f;
        --adm-sidebar-bg: #0d0e13;
        --adm-border: rgba(255, 255, 255, 0.07);
        --adm-text: #f2f3f7;
        --adm-text-dim: rgba(242, 243, 247, 0.65);
        --adm-text-muted: rgba(242, 243, 247, 0.45);
        --adm-text-faint: rgba(242, 243, 247, 0.3);
        --adm-hover: rgba(255, 255, 255, 0.045);
        --adm-active-bg: rgba(255, 255, 255, 0.08);
        --adm-input-bg: rgba(255, 255, 255, 0.05);
        --adm-input-border: rgba(255, 255, 255, 0.12);
        --adm-badge-active-bg: rgba(90, 220, 140, 0.15);
        --adm-badge-active-text: #7ef0ab;
        --adm-badge-blocked-bg: rgba(255, 90, 90, 0.15);
        --adm-badge-blocked-text: #ff9d9d;
        --adm-danger-bg: rgba(255, 90, 90, 0.15);
        --adm-danger-border: rgba(255, 90, 90, 0.5);
        --adm-danger-text: #ff9d9d;
        --adm-flash-error-bg: rgba(255, 90, 90, 0.12);
        --adm-flash-error-border: rgba(255, 90, 90, 0.35);
        --adm-flash-error-text: #ff9d9d;
        --adm-flash-info-bg: rgba(108, 140, 255, 0.12);
        --adm-flash-info-border: rgba(108, 140, 255, 0.35);
        --adm-flash-info-text: #8fb2ff;
        --adm-logo-bg: #101114;
        --adm-logo-text: #f2f3f7;
        --adm-resize:#26262a;
      }

      :root[data-theme="light"] {
        --adm-bg: #ffffff;
        --adm-sidebar-bg: #f5f6f8;
        --adm-border: rgba(15, 17, 23, 0.09);
        --adm-text: #14151a;
        --adm-text-dim: rgba(20, 21, 26, 0.68);
        --adm-text-muted: rgba(20, 21, 26, 0.46);
        --adm-text-faint: rgba(20, 21, 26, 0.32);
        --adm-hover: rgba(15, 17, 23, 0.035);
        --adm-active-bg: rgba(15, 17, 23, 0.07);
        --adm-input-bg: rgba(15, 17, 23, 0.03);
        --adm-input-border: rgba(15, 17, 23, 0.14);
        --adm-badge-active-bg: rgba(22, 163, 74, 0.12);
        --adm-badge-active-text: #15803d;
        --adm-badge-blocked-bg: rgba(220, 38, 38, 0.1);
        --adm-badge-blocked-text: #b91c1c;
        --adm-danger-bg: rgba(220, 38, 38, 0.1);
        --adm-danger-border: rgba(220, 38, 38, 0.4);
        --adm-danger-text: #b91c1c;
        --adm-flash-error-bg: rgba(220, 38, 38, 0.08);
        --adm-flash-error-border: rgba(220, 38, 38, 0.25);
        --adm-flash-error-text: #b91c1c;
        --adm-flash-info-bg: rgba(59, 89, 220, 0.08);
        --adm-flash-info-border: rgba(59, 89, 220, 0.25);
        --adm-flash-info-text: #3d5bd9;
        --adm-logo-bg: #14151a;
        --adm-logo-text: #ffffff;
        --adm-resize:rgba(20, 21, 26, 0.2);
      }

      .adm-shell {
        display: flex;
        min-height: 100vh;
        background: var(--adm-bg);
        color: var(--adm-text);
      }

      /* sidebar */
      .adm-sidebar {
        background: var(--adm-sidebar-bg);
        border-right: 1px solid var(--adm-border);
        display: flex;
        flex-direction: column;
        position: sticky;
        top: 0;
        height: 100vh;
      }

      .adm-logo {
        display: flex;
        align-items: center;
        gap: 10px;
        padding: 18px 20px;
        border-bottom: 1px solid var(--adm-border);
      }

      .adm-logo-mark {
        width: 28px;
        height: 28px;
        border-radius: 7px;
        background: var(--adm-logo-bg);
        display: flex;
        align-items: center;
        justify-content: center;
        color: var(--adm-logo-text);
        font-weight: 700;
        font-size: 12px;
        flex-shrink: 0;
      }

      .adm-logo-text {
        font-weight: 700;
        font-size: 14px;
        letter-spacing: 0.05em;
        color: var(--adm-text);
      }

      .adm-nav {
        flex: 1;
        overflow-y: auto;
        padding: 16px 10px;
      }

      .adm-nav-label {
        margin: 4px 10px 8px;
        font-size: 11px;
        font-weight: 700;
        text-transform: uppercase;
        letter-spacing: 0.08em;
        color: var(--adm-text-muted);
      }

      .adm-nav-group summary {
        list-style: none;
        cursor: pointer;
        display: flex;
        align-items: center;
        gap: 10px;
        padding: 8px 10px;
        border-radius: 7px;
        font-size: 13.5px;
        color: var(--adm-text-dim);
        user-select: none;
      }

      .adm-nav-group summary::-webkit-details-marker {
        display: none;
      }

      .adm-nav-group summary:hover {
        background: var(--adm-hover);
      }

      .adm-nav-chevron {
        margin-left: auto;
        width: 13px;
        height: 13px;
        flex-shrink: 0;
        transition: transform 0.15s ease;
        opacity: 0.6;
      }

      .adm-nav-group[open] > summary .adm-nav-chevron {
        transform: rotate(90deg);
      }

      .adm-nav-icon {
        width: 15px;
        height: 15px;
        flex-shrink: 0;
        opacity: 0.7;
      }

      .adm-nav-sub {
        margin: 2px 0 4px 17px;
        padding-left: 13px;
        border-left: 1px solid var(--adm-border);
        display: flex;
        flex-direction: column;
        gap: 1px;
      }

      .adm-nav-item {
        display: flex;
        align-items: center;
        gap: 9px;
        padding: 7px 10px;
        border-radius: 7px;
        font-size: 13px;
        color: var(--adm-text-muted);
        text-decoration: none;
      }

      .adm-nav-item:hover {
        background: var(--adm-hover);
        color: var(--adm-text);
      }

      .adm-nav-item .adm-dot {
        width: 6px;
        height: 6px;
        border-radius: 50%;
        border: 1.5px solid var(--adm-text-faint);
        flex-shrink: 0;
      }

      .adm-nav-item.active {
        background: var(--adm-active-bg);
        color: var(--adm-text);
        font-weight: 600;
      }

      .adm-nav-item.active .adm-dot {
        background: #6c8cff;
        border-color: #6c8cff;
      }

      .adm-nav-toplevel {
        display: flex;
        align-items: center;
        gap: 10px;
        padding: 8px 10px;
        border-radius: 7px;
        font-size: 13.5px;
        color: var(--adm-text-dim);
        text-decoration: none;
        margin-bottom: 2px;
      }

      .adm-nav-toplevel:hover {
        background: var(--adm-hover);
      }

      .adm-nav-toplevel.active {
        background: var(--adm-active-bg);
        color: var(--adm-text);
        font-weight: 600;
      }

      .adm-sidebar-footer {
        border-top: 1px solid var(--adm-border);
        padding: 12px 14px;
        display: flex;
        align-items: center;
        gap: 8px;
      }

      .adm-avatar {
        width: 28px;
        height: 28px;
        border-radius: 50%;
        background: linear-gradient(135deg, #8fb2ff, #6c8cff);
        color: #0b1120;
        display: flex;
        align-items: center;
        justify-content: center;
        font-weight: 700;
        font-size: 12px;
        flex-shrink: 0;
      }

      .adm-footer-info {
        min-width: 0;
        flex: 1;
      }

      .adm-footer-login {
        font-size: 12.5px;
        font-weight: 600;
        color: var(--adm-text);
        white-space: nowrap;
        overflow: hidden;
        text-overflow: ellipsis;
      }

      .adm-footer-role {
        font-size: 11px;
        color: var(--adm-text-muted);
      }

      .adm-icon-btn {
        flex-shrink: 0;
        width: 28px;
        height: 28px;
        border-radius: 7px;
        border: 1px solid var(--adm-input-border);
        background: var(--adm-input-bg);
        display: flex;
        align-items: center;
        justify-content: center;
        color: var(--adm-text-muted);
        text-decoration: none;
        cursor: pointer;
      }

      .adm-icon-btn:hover {
        background: var(--adm-hover);
        color: var(--adm-text);
      }

      .adm-icon-btn.danger:hover {
        background: var(--adm-danger-bg);
        border-color: var(--adm-danger-border);
        color: var(--adm-danger-text);
      }

      .adm-icon-btn svg {
        width: 14px;
        height: 14px;
      }

      /* main area */
      .adm-main {
        flex: 1;
        min-width: 0;
        display: flex;
        flex-direction: column;
      }

      .adm-topbar {
        display: flex;
        align-items: center;
        justify-content: space-between;
        gap: 16px;
        padding: 18px 28px;
        border-bottom: 1px solid var(--adm-border);
        flex-wrap: wrap;
      }

      .adm-topbar-title {
        display: flex;
        align-items: baseline;
        gap: 10px;
        margin: 0;
      }

      .adm-topbar-title h1 {
        margin: 0;
        font-size: 19px;
        font-weight: 700;
        letter-spacing: 0.01em;
      }

      .adm-topbar-count {
        font-size: 14px;
        font-weight: 600;
        color: var(--adm-text-muted);
      }

      .adm-topbar-actions {
        display: flex;
        align-items: center;
        gap: 8px;
      }

      .adm-topbar-actions .adm-icon-btn {
        width: 32px;
        height: 32px;
      }

      .adm-topbar-actions .adm-icon-btn svg {
        width: 16px;
        height: 16px;
      }

      .adm-content {
        padding: 20px 28px 40px;
      }

      /* buttons (forms) */
      .adm-btn {
        display: inline-flex;
        align-items: center;
        gap: 6px;
        border: none;
        border-radius: 10px;
        padding: 10px 16px;
        font-size: 13.5px;
        font-weight: 600;
        cursor: pointer;
        text-decoration: none;
        transition: filter 0.15s ease, box-shadow 0.15s ease, background 0.15s ease, border-color 0.15s ease, color 0.15s ease;
        white-space: nowrap;
      }

      .adm-btn-primary {
        color: #0b1120;
        background: linear-gradient(135deg, #8fb2ff, #6c8cff);
        display:flex;
        justify-content: center;
        align-items:center;
      }

      .adm-btn-primary:hover {
        filter: brightness(1.05);
        box-shadow: 0 10px 24px rgba(108, 140, 255, 0.35);
      }

      .adm-btn-ghost {
        color: var(--adm-text-dim);
        background: var(--adm-input-bg);
        border: 1px solid var(--adm-input-border);
      }

      .adm-btn-ghost:hover {
        background: var(--adm-hover);
      }

      .adm-btn-danger {
        color: var(--adm-text-dim);
        background: var(--adm-input-bg);
        border: 1px solid var(--adm-input-border);
      }

      .adm-btn-danger:hover {
        background: var(--adm-danger-bg);
        border-color: var(--adm-danger-border);
        color: var(--adm-danger-text);
      }

      .adm-btn-sm {
        padding: 6px 12px;
        font-size: 12.5px;
        border-radius: 8px;
      }

      /* table */
      .adm-table-wrap {
        overflow-x: auto;
      }

      .adm-table {
        width: 100%;
        border-collapse: collapse;
        font-size: 13.5px;
      }

      .adm-table th {
        text-align: left;
        font-size: 11.5px;
        font-weight: 700;
        text-transform: uppercase;
        letter-spacing: 0.05em;
        color: var(--adm-text-muted);
        padding: 0 14px 10px;
        white-space: nowrap;
      }

      .adm-table .adm-filter-row th {
        padding: 0 14px 14px;
        border-bottom: 1px solid var(--adm-border);
        font-weight: 400;
      }

      .adm-search {
        display: flex;
        align-items: center;
        gap: 6px;
        padding: 2px 0;
      }

      .adm-search svg {
        width: 14px;
        height: 14px;
        opacity: 0.4;
        flex-shrink: 0;
      }

      .adm-search input,
      .adm-search select {
        border: none;
        background: transparent;
        outline: none;
        color: var(--adm-text);
        font-size: 13px;
        width: 100%;
        min-width: 0;
        padding: 0;
      }

      .adm-search select option {
        color: #0b1120;
        background: #ffffff;
      }

      .adm-search input::placeholder {
        color: var(--adm-text-faint);
      }

      .adm-table td {
        padding: 12px 14px;
        border-bottom: 1px solid var(--adm-border);
        vertical-align: middle;
        color: var(--adm-text-dim);
      }

      .adm-table tbody tr:last-child td {
        border-bottom: none;
      }

      .adm-table tbody tr:hover td {
        background: var(--adm-hover);
      }

      .adm-table td.adm-col-actions {
        text-align: right;
      }

      .adm-row-actions {
        display: inline-flex;
        gap: 8px;
      }

      .adm-badge {
        display: inline-block;
        padding: 3px 10px;
        border-radius: 999px;
        font-size: 12px;
        font-weight: 600;
      }

      .adm-badge.active {
        background: var(--adm-badge-active-bg);
        color: var(--adm-badge-active-text);
      }

      .adm-badge.blocked {
        background: var(--adm-badge-blocked-bg);
        color: var(--adm-badge-blocked-text);
      }

      .adm-empty {
        text-align: center;
        padding: 40px;
        color: var(--adm-text-muted);
      }

      /* flash */
      .adm-flash {
        margin: 0 0 16px;
        padding: 12px 16px;
        border-radius: 10px;
        font-size: 14px;
      }

      .adm-flash.error {
        background: var(--adm-flash-error-bg);
        border: 1px solid var(--adm-flash-error-border);
        color: var(--adm-flash-error-text);
      }

      .adm-flash.info {
        background: var(--adm-flash-info-bg);
        border: 1px solid var(--adm-flash-info-border);
        color: var(--adm-flash-info-text);
      }

      /* forms (reused by create/edit pages) */
      .adm-form-card {
        max-width: 480px;
      }

      .adm-form {
        display: flex;
        flex-direction: column;
        gap: 16px;
      }

      .adm-field {
        display: flex;
        flex-direction: column;
        gap: 6px;
      }

      .adm-field label {
        font-size: 11px;
        font-weight: 600;
        text-transform: uppercase;
        letter-spacing: 0.06em;
        color: var(--adm-text-muted);
      }

      .adm-field input,
      .adm-field select {
        appearance: none;
        border: 1px solid var(--adm-input-border);
        background: var(--adm-input-bg);
        color: var(--adm-text);
        border-radius: 10px;
        padding: 10px 12px;
        font-size: 14px;
        outline: none;
        transition: border-color 0.15s ease, background 0.15s ease, box-shadow 0.15s ease;
      }

      .adm-field select option {
        color: #0b1120;
        background: #ffffff;
      }

      .adm-field input:focus,
      .adm-field select:focus {
        border-color: #6c8cff;
        box-shadow: 0 0 0 3px rgba(108, 140, 255, 0.2);
      }

      .adm-field-error {
        font-size: 12px;
        color: var(--adm-danger-text);
      }

      .adm-hint {
        font-size: 12px;
        color: var(--adm-text-muted);
      }
      .adm-online{
        background-color: #4DFFBE;
        width:5px;
        height: 5px;
        border-radius: 50%;
        margin-right: 10px;
        animation: dot_pulsation 2s ease-in-out infinite;
      }
      @keyframes dot_pulsation {
        0%{
          box-shadow: none;
        }
        50%{
          box-shadow: 0px 0px 10px#7ef0ab;
        }
        100%{
          box-shadow: none;
        }
      }
      .status__text{
        font-size: 9px;
        font-weight: 700;
        color: var(--adm-text-muted);
        font-family: monospace;
      }
      .admin__status{
        display: flex;
        align-items: center;
        position: relative;
        left: -15px;
      }
      .adm-logo-git{
        display:flex;
        align-items:center;
        transform:translateY(1px);
        text-decoration:none;
        margin-left:10px;
      }
      .adm-logo-git img{
        width: 20px;
        border-radius:50%;
        margin-right:3px;
      }
      .adm-logo-git span{
        font-size: 12.5px;
        font-weight: 600;
        color: var(--adm-text);
        white-space: nowrap;

      }
      .resizer {
        width: 4px;
        cursor: col-resize;
        background-color:var(--adm-resize);
        transition: background-color 0.2s;
        user-select: none;
      }
    </style>

    <div class="adm-shell">
      <aside class="adm-sidebar" id="sidebar">
        <div class="adm-logo">
          <div class="adm-logo-mark">DB</div>
          <span class="adm-logo-text">Data Bus</span>
          <a class="adm-logo-git" href="https://github.com/jakomader/copm"><img src={~p"/github_logo.jpg"}> <span> GitHub Repo</span></a>
        </div>

        <nav class="adm-nav">
          <p class="adm-nav-label">Администрирование</p>

          <details class="adm-nav-group" open={@users_section?}>
            <summary>
              <svg class="adm-nav-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8">
                <path d="M17 20v-1a4 4 0 0 0-4-4H7a4 4 0 0 0-4 4v1" stroke-linecap="round" stroke-linejoin="round" />
                <circle cx="10" cy="7" r="4" />
                <path d="M22 20v-1a4 4 0 0 0-3-3.87M16 3.13a4 4 0 0 1 0 7.75" stroke-linecap="round" stroke-linejoin="round" />
              </svg>
              Управление пользователями
              <svg class="adm-nav-chevron" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M9 18l6-6-6-6" stroke-linecap="round" stroke-linejoin="round" />
              </svg>
            </summary>

            <div class="adm-nav-sub">
              <.link navigate={~p"/admin/users/admins"} class={"adm-nav-item" <> if @active == :admins, do: " active", else: ""}>
                <span class="adm-dot"></span> Администраторы
              </.link>
              <.link navigate={~p"/admin/users/suppliers"} class={"adm-nav-item" <> if @active == :suppliers, do: " active", else: ""}>
                <span class="adm-dot"></span> Поставщики
              </.link>
              <.link navigate={~p"/admin/users/consumers"} class={"adm-nav-item" <> if @active == :consumers, do: " active", else: ""}>
                <span class="adm-dot"></span> Потребители
              </.link>
            </div>
          </details>

          <.link navigate={~p"/admin/orgs"} class={"adm-nav-toplevel" <> if @active == :orgs, do: " active", else: ""}>
            <svg class="adm-nav-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8">
              <rect x="4" y="3" width="16" height="18" rx="1" />
              <path d="M9 8h1M9 12h1M9 16h1M14 8h1M14 12h1M14 16h1" stroke-linecap="round" />
            </svg>
            Организации
          </.link>
        </nav>

        <div class="adm-sidebar-footer">
          <div class="adm-avatar">{initial(@current_operator)}</div>
          <div class="adm-footer-info">
            <div class="adm-footer-login">{login_of(@current_operator)}</div>
            <div class="adm-footer-role">admin</div>
          </div>
          <div class="admin__status"><div class="adm-online"></div> <span class="status__text">Online</span></div>
          <button type="button" class="adm-icon-btn" title="Переключить тему" onclick="window.copmToggleTheme()">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8">
              <path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z" stroke-linecap="round" stroke-linejoin="round" />
            </svg>
          </button>
          <.link href={~p"/logout"} class="adm-icon-btn" title="Выйти">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8">
              <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4" stroke-linecap="round" stroke-linejoin="round" />
              <path d="M16 17l5-5-5-5M21 12H9" stroke-linecap="round" stroke-linejoin="round" />
            </svg>
          </.link>
        </div>
      </aside>
      
      <div id="resizer" class="resizer" phx-hook="SidebarResizer"></div>
      <div class="adm-main">
        <p
          :if={msg = Phoenix.Flash.get(@flash, :error)}
          id="flash-error"
          phx-hook="AutoDismissFlash"
          phx-click="lv:clear-flash"
          phx-value-key="error"
          class="adm-flash error"
          style="margin: 16px 28px 0;"
        >{msg}</p>
        <p
          :if={msg = Phoenix.Flash.get(@flash, :info)}
          id="flash-info"
          phx-hook="AutoDismissFlash"
          phx-click="lv:clear-flash"
          phx-value-key="info"
          class="adm-flash info"
          style="margin: 16px 28px 0;"
        >{msg}</p>

        <header class="adm-topbar">
          <div class="adm-topbar-title">
            <h1>{@title}</h1>
            <span :if={@count} class="adm-topbar-count">{@count}</span>
          </div>
          <div class="adm-topbar-actions">{render_slot(@actions)}</div>
        </header>

        <div class="adm-content">
          {render_slot(@inner_block)}
        </div>
      </div>
    </div>
    """
  end

  defp initial(%{login: login}) when is_binary(login) and login != "", do: login |> String.first() |> String.upcase()
  defp initial(_), do: "A"

  defp login_of(%{login: login}), do: login
  defp login_of(_), do: "admin"
end
