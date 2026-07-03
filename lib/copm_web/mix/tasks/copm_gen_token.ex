defmodule Mix.Tasks.Copm.GenToken do
  use Mix.Task

  @shortdoc "Generates a new API token for GraphQL access"
  @moduledoc """
  Generates a new API token.
  mix copm.gen_token "operator name"
  The raw token is printed once and cannot be recovered afterwards — only
  its hash is stored in the database.
  """

  def run([name | _]) do
    Mix.Task.run("app.start")

    case Copm.Auth.generate_token(name) do
      {:ok, raw_token, _record} ->
        Mix.shell().info("Token for #{name}:")
        Mix.shell().info(raw_token)
        Mix.shell().info("Store this securely — it will not be shown again.")

      {:error, changeset} ->
        Mix.shell().error(inspect(changeset.errors))
    end
  end

  def run(_args) do
    Mix.shell().error("Usage: mix copm.gen_token \"operator name\"")
  end
end
