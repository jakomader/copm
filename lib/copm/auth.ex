defmodule Copm.Auth do
  import Ecto.Query

  alias Copm.Schemas.Operators
  alias Copm.Repo
  alias Copm.Auth.ApiToken
  alias Copm.Auth.RefreshToken

  @token_bytes 32

  def create_operator(attrs) do
    %Copm.Schemas.Operators{}
    |> Copm.Schemas.Operators.changeset(attrs)
    |> Copm.Repo.insert()
  end


  def login(login, password) do
    case Copm.Repo.get_by(Copm.Schemas.Operators, login: login) do
      nil ->
        Bcrypt.no_user_verify()
        :error
      operator ->
        case operator.status do
          "active" -> if (Bcrypt.verify_pass(password, operator.password_hash)) do
            {:ok, operator}
          else
            :error
          end
          "blocked" -> :blocked
          _ -> :error
        end
    end
  end

  def issue_token(operator) do
    raw_token = @token_bytes |> :crypto.strong_rand_bytes() |> Base.url_encode64(padding: false)
    expires_at = DateTime.utc_now() |> DateTime.add(access_token_ttl(), :second) |> DateTime.truncate(:second)
    token_hash = hash_token(raw_token)

    %ApiToken{}
    |> ApiToken.changeset(%{operator_id: operator.id, token_hash: token_hash, expires_at: expires_at})
    |> Repo.insert()
    |> case do
      {:ok, _record} -> {:ok, raw_token}
      {:error, changeset} -> {:error, changeset}
    end
  end

    def issue_refresh_token(operator) do
    raw_token = @token_bytes |> :crypto.strong_rand_bytes() |> Base.url_encode64(padding: false)
    expires_at = DateTime.utc_now() |> DateTime.add(refresh_token_ttl(), :second) |> DateTime.truncate(:second)
    token_hash = hash_token(raw_token)

    %RefreshToken{}
    |> RefreshToken.changeset(%{operator_id: operator.id, token_hash: token_hash, expires_at: expires_at})
    |> Repo.insert()
    |> case do
      {:ok, record} -> {:ok, raw_token, record}
      {:error, changeset} -> {:error, changeset}
    end
  end

  def verify_token(nil), do: :error
  def verify_token(""), do: :error

  def verify_token(raw_token) do
    token_hash = hash_token(raw_token)
    now = DateTime.utc_now()
    query =
      from t in ApiToken,
        where: (t.token_hash == ^token_hash and is_nil(t.revoked_at)) and t.expires_at > ^now,
        preload: :operator

    case Repo.one(query) do
      nil -> :error
      token -> {:ok, token.operator}
    end
  end

  def verify_refresh_token(nil), do: :error
  def verify_refresh_token(""), do: :error

  def verify_refresh_token(raw_token) do
    token_hash = hash_token(raw_token)
    now = DateTime.utc_now()

    query =
      from t in RefreshToken,
        where: (t.token_hash == ^token_hash and is_nil(t.revoked_at)) and t.expires_at > ^now,
        preload: :operator

    case Repo.one(query) do
      nil -> :error
      token -> {:ok, token.operator}
    end
  end
  def rotate_refresh_token(raw_token) do
    token_hash = hash_token(raw_token)

    case Repo.get_by(RefreshToken, token_hash: token_hash) do
      nil -> :error
      token ->
        cond do
          not is_nil(token.revoked_at) ->
            revoke_all_sessions(token.operator_id)
            {:error, :reuse_detected}

          DateTime.before?(token.expires_at, DateTime.utc_now()) -> :error

          true ->
            operator = Repo.preload(token, :operator).operator
            rotate(token, operator)
        end
      end
    end

  #user datas mutations
  def update_user(operator, attrs) do
    operator |> Operators.update_changeset(attrs) |> Repo.update()
  end

  def delete_user(operator) do
    operator |> Repo.delete()
  end

  def block_user(operator) do
    case operator |> Operators.update_changeset(%{status: "blocked"}) |> Repo.update() do
      {:ok, updated} -> revoke_all_sessions(operator.id)
      {:ok, updated}
      {:error, changeset} -> {:error, changeset}
    end
  end



  def revoke_all_sessions(operator_id) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)
    Repo.transaction(fn ->
      from(t in RefreshToken, where: t.operator_id == ^operator_id and is_nil(t.revoked_at))
      |> Repo.update_all(set: [revoked_at: now])

      from(t in ApiToken, where: t.operator_id == ^operator_id and is_nil(t.revoked_at))
      |> Repo.update_all(set: [revoked_at: now])
    end)
  end


  defp rotate(token, operator) do
    Repo.transaction(fn ->
      {:ok, new_refresh_raw, new_refresh_record} = issue_refresh_token(operator)
      {:ok, new_access_raw} = issue_token(operator)
      {:ok, _} =
        token
        |> RefreshToken.changeset(%{
          revoked_at: DateTime.utc_now() |> DateTime.truncate(:second),
          replaced_with_id: new_refresh_record.id
        })
        |> Repo.update()
      %{
        token: new_access_raw,
        expires_in: access_token_ttl(),
        refresh_token: new_refresh_raw,
        operator: operator
      }
    end)
  end

  def generate_session(operator) do
    {:ok, refresh_raw, _record} = issue_refresh_token(operator)
    {:ok, access_raw} = issue_token(operator)
    {:ok, %{
      operator: operator,
      token: access_raw,
      refresh_token: refresh_raw,
      expires_in: access_token_ttl()
    }}
  end

  #для liveview
  def list_operators(attrs) do
    dat = Map.get(attrs, :date, %{})
    Operators
    |> search_pattern(Map.get(attrs, :login))
    |> search_name(Map.get(attrs, :name))
    |> check_role(Map.get(attrs, :role))
    |> check_status(Map.get(attrs, :status))
    |> check_date(Map.get(dat,:from), Map.get(dat, :to))
    |> Repo.all()
    |> Repo.preload(:organization)
  end

  defp search_pattern(q, nil), do: q
  defp search_pattern(q, l), do: where(q, [o], ilike(o.login, ^"#{l}%"))

  defp search_name(q, nil), do: q
  defp search_name(q, n), do: where(q, [o], ilike(o.name, ^"#{n}%"))

  defp check_role(q, nil), do: q
  defp check_role(q, r), do: where(q, [o], o.role == ^r)

  defp check_status(q, nil), do: q
  defp check_status(q, s), do: where(q, [o], o.status == ^s)

  defp check_date(q, nil, nil), do: q
  defp check_date(q, f, t), do: where(q, [o], o.inserted_at > ^f and o.inserted_at < ^t)

  defp hash_token(raw_token) do
    :crypto.hash(:sha256, raw_token) |> Base.encode16(case: :lower)
  end
  defp access_token_ttl(), do: Application.get_env(:copm, :access_token_ttl)
  defp refresh_token_ttl(), do: Application.get_env(:copm, :refresh_token_ttl)

end
