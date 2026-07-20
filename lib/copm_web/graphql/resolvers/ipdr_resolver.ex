defmodule CopmWeb.GraphQL.Resolvers.IpdrResolver do
  import Ecto.Query

  alias Copm.Repo
  alias Copm.Schemas.IpdrRecord

  def list_records(_parent, args, _ctx) do
    query =
      IpdrRecord
      |> filter_org(args[:org_id])
      |> filter_ip(args[:source_ip])
      |> filter_from_ts(args[:from_ts])
      |> filter_to_ts(args[:to_ts])
      |> order_by([r], desc: r.ts)
      |> limit(^args.limit)
      |> offset(^args.offset)

    {:ok, Repo.all(query)}
  end

  defp filter_org(q, nil), do: q
  defp filter_org(q, org_id), do: where(q, [r], r.org_id == ^org_id)

  defp filter_ip(q, nil), do: q
  defp filter_ip(q, ip), do: where(q, [r], r.source_ip == ^ip)

  defp filter_from_ts(q, nil), do: q
  defp filter_from_ts(q, ts), do: where(q, [r], r.ts >= ^ts)

  defp filter_to_ts(q, nil), do: q
  defp filter_to_ts(q, ts), do: where(q, [r], r.ts <= ^ts)
end
