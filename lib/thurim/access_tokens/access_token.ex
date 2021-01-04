defmodule Thurim.AccessTokens.AccessToken do
  use Ecto.Schema
  alias Thurim.User.Account
  alias Thurim.Devices.Device
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "access_tokens" do
    belongs_to :account, Account, references: :localpart, type: :string, foreign_key: :localpart
    belongs_to :device, Device, references: :session_id, foreign_key: :device_session_id

    timestamps()
  end

  @doc false
  def changeset(access_token, attrs) do
    access_token
    |> cast(attrs, [])
    |> validate_required([])
  end
end
