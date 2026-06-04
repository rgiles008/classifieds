defmodule Sunstate.Listings.Expiry do
  @moduledoc """
  Expires old listings. Run periodically via a scheduled task.
  """

  import Ecto.Query
  alias Sunstate.Repo
  alias Sunstate.Listings.Listing

  @doc """
  Expires active listings that have passed their `expires_at` date.
  Returns the count of expired listings.
  """
  def expire_old_listings do
    now = DateTime.utc_now()

    {count, _} =
      Listing
      |> where([l], l.status == "active")
      |> where([l], not is_nil(l.expires_at))
      |> where([l], l.expires_at < ^now)
      |> Repo.update_all(set: [status: "expired"])

    count
  end

  @doc """
  Sets default expiry on listings that don't have one (30 days from creation).
  """
  def set_default_expiry(days \\ 30) do
    cutoff = DateTime.utc_now() |> DateTime.add(-days * 86400)

    {count, _} =
      Listing
      |> where([l], l.status == "active")
      |> where([l], is_nil(l.expires_at))
      |> where([l], l.inserted_at < ^cutoff)
      |> Repo.update_all(set: [status: "expired"])

    count
  end
end
