defmodule Mix.Tasks.Copm.IngestCsv do
  use Mix.Task

  @shortdoc "Читает CSV-выгрузку заказчика и публикует данные в Kafka по топикам"


  @impl Mix.Task
  def run([file]) do
    Mix.Task.run("app.start")

    case Copm.CsvSwallower.ingest(file) do
      {:error, reason} ->
        Mix.shell().error("Неудалось запустить обработку: #{inspect(reason)}")

      %{ok: ok, error: errors} ->
        Mix.shell().info("Обработано строк: #{ok}")

        if errors != [] do
          Mix.shell().error("Ошибок: #{length(errors)}")
          Enum.each(errors, &Mix.shell().error("  #{inspect(&1)}"))
        end
    end
  end

  def run(_args) do
    Mix.shell().error("Usage: mix copm.ingest_csv path/to/file.csv")
  end
end
