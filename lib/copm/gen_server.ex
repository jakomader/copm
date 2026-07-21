defmodule Copm.GenServer do
  use GenServer
  require Logger
  import Ecto.Query
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    schedule_import()
    {:ok, %{}}
  end

  @impl true
  def handle_info(:import_feed, state) do
    Logger.info("Starting auto garbage collecting")

    clear_batches()
    Logger.info("Garbage successfully deleted.")
    schedule_import()
    {:noreply, state}

    end
  defp clear_batches do
    Copm.Repo.delete_all(from e in Copm.Schemas.IngestBatches, where: e.inserted_at <= ago(1, "day"))
    Copm.Repo.delete_all(from e in Copm.Schemas.IngestBatchErrors, where: e.inserted_at <= ago(1, "day"))
  end
  defp schedule_import do
    Process.send_after(self(), :import_feed, 2 * 24 * 60 * 60 * 1000)
  end
end
