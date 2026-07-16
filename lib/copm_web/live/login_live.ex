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

      .login-page {
        display: flex;
        justify-content: center;
        align-items: center;
        min-height: 100vh;
        background: radial-gradient(circle at top, #1e2a4a 0%, #0b1120 65%);
        padding: 16px;
      }

      .login-card {
        width: 100%;
        max-width: 380px;
        background: rgba(255, 255, 255, 0.06);
        border: 1px solid rgba(255, 255, 255, 0.12);
        border-radius: 16px;
        padding: 40px 32px;
        box-shadow: 0 20px 60px rgba(0, 0, 0, 0.45);
        backdrop-filter: blur(14px);
        color: #f4f6fb;
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
        color: rgba(244, 246, 251, 0.6);
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
        color: rgba(244, 246, 251, 0.55);
      }

      .login-field input {
        appearance: none;
        border: 1px solid rgba(255, 255, 255, 0.16);
        background: rgba(255, 255, 255, 0.06);
        color: #f4f6fb;
        border-radius: 10px;
        padding: 12px 14px;
        font-size: 15px;
        outline: none;
        transition: border-color 0.15s ease, background 0.15s ease, box-shadow 0.15s ease;
      }

      .login-field input::placeholder {
        color: rgba(244, 246, 251, 0.35);
      }

      .login-field input:focus {
        border-color: #6c8cff;
        background: rgba(108, 140, 255, 0.1);
        box-shadow: 0 0 0 3px rgba(108, 140, 255, 0.25);
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
        background: rgba(255, 255, 255, 0.06);
        border: 1px solid rgba(255, 255, 255, 0.12);
        border-radius: 10px;
        padding: 16px;
        word-break: break-all;
        font-size: 13px;
        line-height: 1.5;
      }

      .login-token-box p {
        margin: 0 0 8px;
        color: rgba(244, 246, 251, 0.7);
      }

      .login-token-box code {
        display: block;
        background: rgba(0, 0, 0, 0.35);
        border-radius: 6px;
        padding: 10px;
        color: #8fb2ff;
      }

      .login-error {
        margin: 16px 0 0;
        padding: 10px 14px;
        border-radius: 8px;
        background: rgba(255, 90, 90, 0.12);
        border: 1px solid rgba(255, 90, 90, 0.35);
        color: #ff9d9d;
        font-size: 13px;
        text-align: center;
      }
    </style>

    <div class="login-page">
      <div class="login-card">
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
          <p>Ваш bearer-токен (сохраните — показывается один раз):</p>
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
