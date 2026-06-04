defmodule Sunstate.Locations do
  @moduledoc """
  The Locations context for zip code lookups and distance calculations.
  """

  import Ecto.Query
  alias Sunstate.Repo
  alias Sunstate.Locations.ZipCode

  def get_zip_code(zip), do: Repo.get(ZipCode, zip)

  def get_zip_code!(zip), do: Repo.get!(ZipCode, zip)

  def search_cities(query) when is_binary(query) do
    pattern = "%#{query}%"

    ZipCode
    |> where([z], ilike(z.city, ^pattern))
    |> distinct([z], z.city)
    |> select([z], %{city: z.city, zip: z.zip, county: z.county})
    |> order_by([z], z.city)
    |> limit(10)
    |> Repo.all()
  end

  @doc """
  Find zip codes within a radius (in miles) of a given zip code.
  Uses the Haversine formula approximation.
  """
  def zip_codes_within_radius(zip, radius_miles) do
    case get_zip_code(zip) do
      nil ->
        []

      %ZipCode{latitude: lat, longitude: lng} ->
        # Approximate degrees per mile
        lat_range = radius_miles / 69.0
        lng_range = radius_miles / (69.0 * :math.cos(lat * :math.pi() / 180))

        ZipCode
        |> where([z], z.latitude >= ^(lat - lat_range) and z.latitude <= ^(lat + lat_range))
        |> where([z], z.longitude >= ^(lng - lng_range) and z.longitude <= ^(lng + lng_range))
        |> Repo.all()
        |> Enum.filter(fn z ->
          haversine_miles(lat, lng, z.latitude, z.longitude) <= radius_miles
        end)
    end
  end

  defp haversine_miles(lat1, lng1, lat2, lng2) do
    dlat = (lat2 - lat1) * :math.pi() / 180
    dlng = (lng2 - lng1) * :math.pi() / 180
    rlat1 = lat1 * :math.pi() / 180
    rlat2 = lat2 * :math.pi() / 180

    a =
      :math.sin(dlat / 2) * :math.sin(dlat / 2) +
        :math.cos(rlat1) * :math.cos(rlat2) *
          :math.sin(dlng / 2) * :math.sin(dlng / 2)

    c = 2 * :math.atan2(:math.sqrt(a), :math.sqrt(1 - a))
    3959.0 * c
  end
end
