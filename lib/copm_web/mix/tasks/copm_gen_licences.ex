defmodule Mix.Tasks.Copm.GenLicences do
  use Mix.Task

  @shortdoc "Generates N number of licences([login] [password]). Args: role, count"

  def run(args) do
    {:ok, _} = Application.ensure_all_started(:postgrex)
    {:ok, _} = Application.ensure_all_started(:ecto_sql)
    {:ok, _pid} = Copm.Repo.start_link()
    {opts, _, _} =
      OptionParser.parse(args, strict: [count: :integer, role: :string])

    count = Keyword.get(opts, :count, 1)
    role = Keyword.get(opts, :role, "queries_only")
    Copm.Auth.create_operators(role, count)
    |> Enum.each(fn {:ok, %{login: login, password: password}} ->
      Mix.shell().info("Login: #{login} | Password: #{password}")
      {:error, changeset} ->
        Mix.shell().error(inspect(changeset.errors))
    end)
  end

end
