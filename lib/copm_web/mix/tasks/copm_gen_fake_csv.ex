defmodule Mix.Tasks.Copm.GenFakeCsv do
  use Mix.Task

  @shortdoc "Генерирует фейковый CSV в формате, который читает Copm.CsvSwallower.Csv"


  alias Copm.CsvSwallower.Generator

  @impl Mix.Task
  def run(args) do
    {opts, _, _} =
      OptionParser.parse(args, strict: [count: :integer, seed: :integer, out: :string])

    count = Keyword.get(opts, :count, 20)
    seed = Keyword.get(opts, :seed, 42)
    out = Keyword.get(opts, :out, "fake_data.csv")

    Generator.write(out, count, seed)
    Mix.shell().info("Записано #{count} строк в #{out}")
  end
end
