defmodule Copm.Auth do
  import Ecto.Query

  alias Copm.Repo
  alias Copm.Auth.ApiToken

  @token_bytes 32

  def create_operator(role) do
    login = gen_login()
    password = gen_pas()
    changeset = Copm.Schemas.Operators.changeset(%Copm.Schemas.Operators{}, %{login: login, role: role, password: password})
    case Copm.Repo.insert(changeset) do
      {:ok, _operator} -> {:ok, %{login: login, password: password}}
      {:error, changeset} -> {:error, changeset}
    end
  end

  def create_operators(role, count) do
    Enum.map(1..count, fn _ -> create_operator(role) end)
  end

  def login(login, password) do
    case Copm.Repo.get_by(Copm.Schemas.Operators, login: login) do
      nil ->
        Bcrypt.no_user_verify()
        :error
      operator ->
        if (Bcrypt.verify_pass(password, operator.password_hash)) do
          {:ok, operator}
        else
          :error
        end
    end
  end

  def issue_token(operator) do
    raw_token = @token_bytes |> :crypto.strong_rand_bytes() |> Base.url_encode64(padding: false)
    token_hash = hash_token(raw_token)

    %ApiToken{}
    |> ApiToken.changeset(%{operator_id: operator.id, token_hash: token_hash})
    |> Repo.insert()
    |> case do
      {:ok, _record} -> {:ok, raw_token}
      {:error, changeset} -> {:error, changeset}
    end
  end

  @doc """
  Проверяет сырой bearer-токен из запроса, возвращает привязанного оператора.
  """
  def verify_token(nil), do: :error
  def verify_token(""), do: :error

  def verify_token(raw_token) do
    token_hash = hash_token(raw_token)

    query =
      from t in ApiToken,
        where: t.token_hash == ^token_hash and is_nil(t.revoked_at),
        preload: :operator

    case Repo.one(query) do
      nil -> :error
      token -> {:ok, token.operator}
    end
  end

  defp hash_token(raw_token) do
    :crypto.hash(:sha256, raw_token) |> Base.encode16(case: :lower)
  end

  defp gen_pas do
    :crypto.strong_rand_bytes(16)
    |> Base.url_encode64(padding: false)
  end
  defp gen_login do
    "OP-"<> (:crypto.strong_rand_bytes(16)
    |> Base.url_encode64(padding: false))
  end
end
