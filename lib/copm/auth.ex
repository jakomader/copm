defmodule Copm.Auth do
  import Ecto.Query

  alias Copm.Repo
  alias Copm.Auth.ApiToken

  @token_bytes 32

  @doc """
  Generates a new API token for the given name(operator/serice identifier ).
  Returns a raw token once - it cannot be recovered
  """

  def generate_token(name) do
    raw_token = @token_bytes |> :crypto.strong_rand_bytes() |> Base.url_encode64(padding: false)
    token_hash = hash_token(raw_token)
    %ApiToken{}
    |> ApiToken.changeset(%{name: name, token_hash: token_hash})
    |> Repo.insert()
    |> case do
      {:ok, record} -> {:ok, raw_token, record}
      {:error, changeset} -> {:error, changeset}
    end
  end

  @doc """
  Verifies a raw token an incoming request.
  """
  def verify_token(nil), do: :error
  def verify_token(""), do: :error
  def verify_token(raw_token) do
    token_hash = hash_token(raw_token)

    query =
      from t in ApiToken,
        where: t.token_hash == ^token_hash and is_nil(t.revoked_at)

    case Repo.one(query) do
      nil -> :error
      token -> {:ok, token}
    end
  end

  def revoke_token(%ApiToken{} = token) do
    token
    |> ApiToken.changeset(%{revoked_at: DateTime.utc_now() |> DateTime.truncate(:second)})
    |> Repo.update()
  end

  defp hash_token(raw_token) do
    :crypto.hash(:sha256, raw_token) |> Base.encode16(case: :lower)
  end
end
