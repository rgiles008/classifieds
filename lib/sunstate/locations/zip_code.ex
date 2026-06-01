defmodule Sunstate.Locations.ZipCode do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:zip, :string, autogenerate: false}
  schema "zip_codes" do
    field :city, :string
    field :county, :string
    field :latitude, :float
    field :longitude, :float

    timestamps()
  end

  def changeset(zip_code, attrs) do
    zip_code
    |> cast(attrs, [:zip, :city, :county, :latitude, :longitude])
    |> validate_required([:zip, :city, :latitude, :longitude])
    |> validate_format(:zip, ~r/^\d{5}$/, message: "must be a 5-digit zip code")
  end
end
