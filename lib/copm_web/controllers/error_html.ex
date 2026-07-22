defmodule CopmWeb.ErrorHTML do
  @moduledoc """
  Renders HTML error pages (registered as the `html` format under
  `render_errors` in config.exs). `render/2` receives templates named
  like "404.html", "500.html", etc.
  """
  use CopmWeb, :html

  def render(template, assigns) do
    status = template |> String.split(".") |> List.first()

    assigns =
      Map.merge(assigns, %{
        status: status,
        title: title_for(status),
        message: message_for(status)
      })

    error_page(assigns)
  end

  defp title_for("404"), do: "Страница не найдена"
  defp title_for("403"), do: "Доступ запрещён"
  defp title_for("500"), do: "Ошибка сервера"
  defp title_for(_), do: "Что-то пошло не так"

  defp message_for("404"), do: "Такой страницы не существует, либо она была перемещена."
  defp message_for("403"), do: "У вас нет доступа к этому разделу."
  defp message_for("500"), do: "Мы уже знаем о проблеме и разбираемся с ней."
  defp message_for(_), do: "Попробуйте вернуться на главную страницу."

  defp error_page(assigns) do
    ~H"""
    <!DOCTYPE html>
    <html lang="ru">
      <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <title>{@status} · Copm</title>
        <script>
          (function () {
            var stored = localStorage.getItem("copm-theme");
            document.documentElement.dataset.theme = stored === "light" ? "light" : "dark";
          })();
          window.copmToggleTheme = function () {
            var root = document.documentElement;
            var next = root.dataset.theme === "dark" ? "light" : "dark";
            root.dataset.theme = next;
            localStorage.setItem("copm-theme", next);
          };
        </script>
        <style>
          body {
            margin: 0;
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
          }

          :root[data-theme="dark"] {
            --err-bg: #0a0b0f;
            --err-text: #f2f3f7;
            --err-muted: rgba(242, 243, 247, 0.5);
            --err-card-bg: rgba(255, 255, 255, 0.05);
            --err-card-border: rgba(255, 255, 255, 0.1);
            --err-switch-bg: rgba(255, 255, 255, 0.06);
            --err-switch-border: rgba(255, 255, 255, 0.14);
          }

          :root[data-theme="light"] {
            --err-bg: #ffffff;
            --err-text: #14151a;
            --err-muted: rgba(20, 21, 26, 0.5);
            --err-card-bg: #f5f6f8;
            --err-card-border: rgba(15, 17, 23, 0.1);
            --err-switch-bg: rgba(15, 17, 23, 0.04);
            --err-switch-border: rgba(15, 17, 23, 0.12);
          }

          .error-page {
            position: relative;
            min-height: 100vh;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            gap: 8px;
            padding: 24px;
            background: var(--err-bg);
            color: var(--err-text);
            text-align: center;
          }

          .error-status {
            font-size: 72px;
            font-weight: 700;
            line-height: 1;
            letter-spacing: -0.02em;
          }

          .error-title {
            margin: 4px 0 0;
            font-size: 20px;
            font-weight: 700;
          }

          .error-message {
            margin: 0 0 20px;
            max-width: 380px;
            font-size: 14px;
            color: var(--err-muted);
          }

          .error-link {
            display: inline-flex;
            align-items: center;
            gap: 6px;
            border: 1px solid var(--err-card-border);
            background: var(--err-card-bg);
            color: var(--err-text);
            border-radius: 10px;
            padding: 10px 18px;
            font-size: 14px;
            font-weight: 600;
            text-decoration: none;
          }

          .error-link:hover {
            filter: brightness(1.08);
          }

          .theme-switch {
            position: absolute;
            top: 18px;
            right: 18px;
            width: 36px;
            height: 36px;
            border-radius: 9px;
            border: 1px solid var(--err-switch-border);
            background: var(--err-switch-bg);
            color: var(--err-muted);
            display: flex;
            align-items: center;
            justify-content: center;
            cursor: pointer;
          }

          .theme-switch svg {
            width: 16px;
            height: 16px;
          }
        </style>
      </head>
      <body>
        <div class="error-page">
          <button type="button" class="theme-switch" title="Переключить тему" onclick="window.copmToggleTheme()">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8">
              <path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z" stroke-linecap="round" stroke-linejoin="round" />
            </svg>
          </button>

          <div class="error-status">{@status}</div>
          <h1 class="error-title">{@title}</h1>
          <p class="error-message">{@message}</p>
          <.link navigate={~p"/login"} class="error-link">На главную</.link>
        </div>
      </body>
    </html>
    """
  end
end
