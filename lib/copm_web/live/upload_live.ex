defmodule CopmWeb.UploadLive do
  use CopmWeb, :live_view

  alias Copm.Repo
  alias Copm.Schemas.Operators

  def mount(_params, session, socket) do
    with operator_id when not is_nil(operator_id) <- session["operator_id"],
         %Operators{role: "data_provider"} = operator <- Repo.get(Operators, operator_id) do
      socket =
        socket
        |> assign(operator: operator, result: nil)
        |> allow_upload(:csv, accept: ~w(.csv), max_entries: 1, max_file_size: 200_000_000)

      {:ok, socket}
    else
      _ -> {:ok, redirect(socket, to: ~p"/login")}
    end
  end

  def render(assigns) do
    ~H"""
    <div style="display:flex;justify-content:center; align-items:center; min-height:100vh;flex-direction:column;gap:10px;">
      <h1>Загрузка CSV</h1>
      <form phx-submit="upload" phx-change="validate" style="display:flex;flex-direction:column;gap:10px;">
        <.live_file_input upload={@uploads.csv} />
        <button type="submit">Upload</button>
      </form>
      <p :if={@result}>{@result}</p>
    </div>
    """
  end

  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("upload", _params, socket) do
    paths =
      consume_uploaded_entries(socket, :csv, fn %{path: path}, entry ->
        dest = Path.join(System.tmp_dir!(), entry.client_name)
        File.cp!(path, dest)
        {:ok, dest}
      end)

    case paths do
      [path] ->
        task = Task.async(fn -> Copm.CsvSwallower.ingest(path) end)
        {:noreply, assign(socket, result: "Обработка запущена…", task_ref: task.ref)}

      [] ->
        {:noreply, assign(socket, result: "Файл не выбран")}
    end
  end

  def handle_info({ref, result}, %{assigns: %{task_ref: ref}} = socket) do
    Process.demonitor(ref, [:flush])
    {:noreply, assign(socket, result: inspect(result), task_ref: nil)}
  end
end
