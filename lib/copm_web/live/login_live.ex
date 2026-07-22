defmodule CopmWeb.LoginLive do
  use CopmWeb, :live_view
  alias Copm.Auth
  def mount(_params, _session, socket) do
    socket = assign(socket, error: nil, bearer_token: nil)
    {:ok, socket}
  end
  def render(assigns) do
    ~H"""
    <style>
      body {
        overflow: hidden;
        margin: 0;
        font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
      }

      :root[data-theme="light"] {
        --login-bg: #f5f6f8;
        --login-card-bg: #ffffff;
        --login-card-border: #e5e7eb;
        --login-card-shadow: 0 20px 50px rgba(15, 23, 42, 0.08);
        --login-text: #14171f;
        --login-subtitle: #6b7280;
        --login-label: #7a8290;
        --login-input-bg: #f9fafb;
        --login-input-border: #d8dbe0;
        --login-input-text: #14171f;
        --login-input-placeholder: #9aa1ad;
        --login-focus-border: #6c8cff;
        --login-focus-ring: rgba(108, 140, 255, 0.18);
        --login-focus-bg: #f2f5ff;
        --login-token-bg: #f3f5ff;
        --login-token-border: #e1e5ff;
        --login-token-text: #4b5468;
        --login-token-code-bg: #eef1f8;
        --login-token-code-text: #3d5bd9;
        --login-error-bg: #fff1f1;
        --login-error-border: #ffd6d6;
        --login-error-text: #d92d2d;
        --login-switch-bg: #e5e7eb;
        --login-switch-border: #d8dbe0;
        --login-switch-icon: #6b7280;
      }

      :root[data-theme="dark"] {
        --login-bg: #0a0b0f;
        --login-card-bg: rgba(255, 255, 255, 0.05);
        --login-card-border: rgba(255, 255, 255, 0.12);
        --login-card-shadow: 0 20px 60px rgba(0, 0, 0, 0.45);
        --login-text: #f4f6fb;
        --login-subtitle: rgba(244, 246, 251, 0.6);
        --login-label: rgba(244, 246, 251, 0.55);
        --login-input-bg: rgba(255, 255, 255, 0.06);
        --login-input-border: rgba(255, 255, 255, 0.16);
        --login-input-text: #f4f6fb;
        --login-input-placeholder: rgba(244, 246, 251, 0.35);
        --login-focus-border: #6c8cff;
        --login-focus-ring: rgba(108, 140, 255, 0.25);
        --login-focus-bg: rgba(108, 140, 255, 0.1);
        --login-token-bg: rgba(255, 255, 255, 0.06);
        --login-token-border: rgba(255, 255, 255, 0.12);
        --login-token-text: rgba(244, 246, 251, 0.7);
        --login-token-code-bg: rgba(0, 0, 0, 0.35);
        --login-token-code-text: #8fb2ff;
        --login-error-bg: rgba(255, 90, 90, 0.12);
        --login-error-border: rgba(255, 90, 90, 0.35);
        --login-error-text: #ff9d9d;
        --login-switch-bg: rgba(255, 255, 255, 0.1);
        --login-switch-border: rgba(255, 255, 255, 0.18);
        --login-switch-icon: #f4f6fb;
      }

      .login-page {
        display: flex;
        justify-content: center;
        align-items: center;
        min-height: 100vh;
        background: var(--login-bg, #f5f6f8);
        padding: 16px;
        transition: background 0.2s ease;
      }

      .login-card {
        position: relative;
        width: 100%;
        max-width: 380px;
        background: var(--login-card-bg);
        border: 1px solid var(--login-card-border);
        border-radius: 16px;
        padding: 40px 32px;
        box-shadow: var(--login-card-shadow);
        backdrop-filter: blur(14px);
        color: var(--login-text);
        transition: background 0.2s ease, border-color 0.2s ease, color 0.2s ease;
      }

      .theme-switch {
        position: absolute;
        top: 18px;
        right: 18px;
        width: 40px;
        height: 40px;
        border-radius: 10px;
        border: 1px solid var(--login-switch-border);
        background: var(--login-switch-bg);
        color: var(--login-switch-icon);
        display: flex;
        align-items: center;
        justify-content: center;
        cursor: pointer;
        transition: background 0.15s ease, border-color 0.15s ease;
      }

      .theme-switch:hover {
        filter: brightness(0.97);
      }

      .theme-switch svg {
        width: 18px;
        height: 18px;
      }

      .theme-switch .icon-sun {
        display: none;
      }

      :root[data-theme="light"] .theme-switch .icon-moon {
        display: block;
      }

      :root[data-theme="light"] .theme-switch .icon-sun {
        display: none;
      }

      :root[data-theme="dark"] .theme-switch .icon-moon {
        display: none;
      }

      :root[data-theme="dark"] .theme-switch .icon-sun {
        display: block;
      }

      .login-title {
        margin: 0 0 6px;
        font-size: 26px;
        font-weight: 700;
        text-align: center;
        letter-spacing: 0.02em;
      }

      .login-subtitle {
        margin: 0 0 28px;
        text-align: center;
        font-size: 14px;
        color: var(--login-subtitle);
      }

      .login-form {
        display: flex;
        flex-direction: column;
        gap: 16px;
      }

      .login-field {
        display: flex;
        flex-direction: column;
        gap: 6px;
      }

      .login-field label {
        font-size: 12px;
        font-weight: 600;
        text-transform: uppercase;
        letter-spacing: 0.06em;
        color: var(--login-label);
      }

      .login-field input {
        appearance: none;
        border: 1px solid var(--login-input-border);
        background: var(--login-input-bg);
        color: var(--login-input-text);
        border-radius: 10px;
        padding: 12px 14px;
        font-size: 15px;
        outline: none;
        transition: border-color 0.15s ease, background 0.15s ease, box-shadow 0.15s ease;
      }

      .login-field input::placeholder {
        color: var(--login-input-placeholder);
      }

      .login-field input:focus {
        border-color: var(--login-focus-border);
        background: var(--login-focus-bg);
        box-shadow: 0 0 0 3px var(--login-focus-ring);
      }

      .login-submit {
        margin-top: 8px;
        border: none;
        border-radius: 10px;
        padding: 13px 16px;
        font-size: 15px;
        font-weight: 600;
        color: #0b1120;
        background: linear-gradient(135deg, #8fb2ff, #6c8cff);
        cursor: pointer;
        transition: transform 0.15s ease, box-shadow 0.15s ease, filter 0.15s ease;
      }

      .login-submit:hover {
        filter: brightness(1.05);
        box-shadow: 0 10px 24px rgba(108, 140, 255, 0.35);
      }

      .login-submit:active {
        transform: translateY(1px);
      }

      .login-token-box {
        background: var(--login-token-bg);
        border: 1px solid var(--login-token-border);
        border-radius: 10px;
        padding: 16px;
        word-break: break-all;
        font-size: 13px;
        line-height: 1.5;
      }

      .login-token-box p {
        margin: 0 0 8px;
        color: var(--login-token-text);
      }

      .login-token-box code {
        display: block;
        background: var(--login-token-code-bg);
        border-radius: 6px;
        padding: 10px;
        color: var(--login-token-code-text);
      }

      .login-error {
        margin: 16px 0 0;
        padding: 10px 14px;
        border-radius: 8px;
        background: var(--login-error-bg);
        border: 1px solid var(--login-error-border);
        color: var(--login-error-text);
        font-size: 13px;
        text-align: center;
      }
    </style>

    <div class="login-page">
      <div class="login-card">
        <button
          type="button"
          class="theme-switch"
          title="Переключить тему"
          onclick="window.copmToggleTheme()"
        >
          <svg class="icon-moon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8">
            <path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z" stroke-linecap="round" stroke-linejoin="round" />
          </svg>
          <svg class="icon-sun" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8">
            <circle cx="12" cy="12" r="4" />
            <path d="M12 2v2M12 20v2M4.93 4.93l1.41 1.41M17.66 17.66l1.41 1.41M2 12h2M20 12h2M4.93 19.07l1.41-1.41M17.66 6.34l1.41-1.41" stroke-linecap="round" />
          </svg>
        </button>

        <h1 class="login-title">Вход</h1>
        <p class="login-subtitle">Личный кабинет администратора</p>

        <.form :if={is_nil(@bearer_token)} class="login-form" for={%{}} phx-submit="login">
          <div class="login-field">
            <label for="login">Логин</label>
            <input type="text" id="login" name="login" placeholder="Введите логин" required />
          </div>
          <div class="login-field">
            <label for="password">Пароль</label>
            <input type="password" id="password" name="password" placeholder="Введите пароль" required />
          </div>
          <button class="login-submit" type="submit">Войти</button>
        </.form>

        <div :if={@bearer_token} class="login-token-box">
          <p>Ваш bearer-токен (сохраните - показывается один раз):</p>
          <code>{@bearer_token}</code>
        </div>

        <p :if={@error} class="login-error">{@error}</p>
      </div>
    </div>
    """
  end

  def handle_event("login", %{"login" => login, "password" => password}, socket) do
    case Auth.login(login, password) do
      {:ok, %{role: "admin"} = operator} ->
        token = Phoenix.Token.sign(CopmWeb.Endpoint, "admin_session", operator.id)
        {:noreply, redirect(socket, to: ~p"/session/new?t=#{token}")}
      {:ok, %{role: _}} -> {:noreply, assign(socket, error: "403 Forbidden. You have no access to this resource.")}
      :blocked ->
        {:noreply, assign(socket, error: "Пользователь заблокирован")}
      :error ->
        {:noreply, assign(socket, error: "Неверный логин/пароль")}
    end
  end
end
