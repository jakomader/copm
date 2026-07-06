defmodule CopmWeb.LoginLive do
  use CopmWeb, :live_view
  alias Copm.Auth
  def mount(_params, _session, socket) do
    socket = assign(socket, error: nil, bearer_token: nil)
    {:ok, socket}
  end
  def render(assigns) do
    ~H"""
    <style>body{overflow:hidden;}</style>
    <div style="display:flex;justify-content:center; align-items:center; min-height:100vh;flex-direction:column;">
    <h1> Вход </h1>
    <.form :if={is_nil(@bearer_token)} style="display:flex;flex-direction:column;padding:20px;border:1px solid black; border-radius:10px;gap:10px;max-width:20vw;width:100%;" for={%{}} phx-submit="login">
      <input type="text" name="login" placeholder="Логин" required />
      <input type="password" name="password" placeholder="Пароль" required />
      <button style="width:50%;position:relative;left:50%;transform:translateX(-50%);background:aqua;border:1px solid black;border-radius:10px;" type="submit">Войти</button>
    </.form>
    <div :if={@bearer_token} style="padding:20px;border:1px solid black; border-radius:10px;max-width:40vw;word-break:break-all;">
      <p>Ваш bearer-токен (сохраните — показывается один раз):</p>
      <code>{@bearer_token}</code>
    </div>
    <p :if={@error}>{@error}</p>
    </div>
    """
  end

  def handle_event("login", %{"login" => login, "password" => password}, socket) do
    case Auth.login(login, password) do
      {:ok, %{role: "queries_only"} = operator} ->
        case Auth.issue_token(operator) do
          {:ok, raw_token} ->
            {:noreply, assign(socket, bearer_token: raw_token, error: nil)}

          {:error, _changeset} ->
            {:noreply, assign(socket, error: "Не удалось выдать токен, попробуйте ещё раз")}
        end

      {:ok, %{role: "data_provider"} = operator} ->
        token = Phoenix.Token.sign(CopmWeb.Endpoint, "data_provider_session", operator.id)
        {:noreply, redirect(socket, to: ~p"/session/new?token=#{token}")}

      :error ->
        {:noreply, assign(socket, error: "Неверный логин/пароль")}
    end
  end
end
