defmodule CopmWeb.GraphQL.Resolvers.SessionResolver do
  alias Copm.Auth
  def session_create(_parent, %{login: login, password: password}, _ctx) do
    case Auth.login(login, password) do
      {:ok, operator} -> Auth.generate_session(operator)
      :error -> {:error, "Login or password are incorrect / No user found / User status is undefined"}
      :blocked -> {:error, "User is blocked"}
    end
  end
#      resolve &SessionResolver.user_create/3

#      resolve &SessionResolver.user_update/3

#      resolve &SessionResolver.user_delete/3

#      resolve &SessionResolver.user_block/3

  def session_refresh(_parent, %{refresh_token: refresh}, _ctx) do
    case Auth.rotate_refresh_token(refresh) do
      :error -> {:error, "Invalid or expired refresh-token"}
      {:error, :reuse_detected} -> {:error, "user refresh token has been used twice"}
      {:ok, session} -> {:ok, session}
    end
  end
  def user_create(_p, args, _c) do
    case Auth.create_operator(args) do
      {:ok, changeset} -> {:ok, changeset}
      {:error, changeset} -> {:error, Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)}
    end
  end
  def user_update(_p, %{operator_id: operator_id} = attrs , _c) do
    case Copm.Repo.get(Copm.Schemas.Operators, operator_id) do
      nil -> {:error, "^-^ Record was not found ^-^ "}
      operator ->
        Auth.update_user(operator, attrs)
    end
  end

  def user_delete(_p, %{operator_id: operator_id}, _c) do
    case Copm.Repo.get(Copm.Schemas.Operators, operator_id) do
      nil -> {:error, "^-^ Record was not found ^-^ "}
      operator ->
        Auth.delete_user(operator)
    end
  end
  def user_block(_p, %{operator_id: operator_id}, _c) do
    case Copm.Repo.get(Copm.Schemas.Operators, operator_id) do
      nil -> {:error, "^-^ Record was not found ^-^ "}
      operator ->
        Auth.block_user(operator)
    end
  end

end
