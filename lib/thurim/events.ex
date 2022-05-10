defmodule Thurim.Events do
  @moduledoc """
  The Events context.
  """

  import Ecto.Query, warn: false
  alias Thurim.Repo

  alias Thurim.Events.Event
  alias Thurim.Events.EventStateKey

  @default_power_levels %{
    "ban" => 50,
    "events" => %{
      "m.room.avatar" => 50,
      "m.room.canonical_alias" => 50,
      "m.room.history_visibility" => 100,
      "m.room.name" => 50,
      "m.room.power_levels" => 100,
      "m.room.server_acl" => 100,
      "m.room.tombstone" => 100,
      "m.space.child" => 50,
      "m.room.topic" => 50,
      "m.room.pinned_events" => 50,
      "m.reaction" => 0,
      "im.vector.modular.widgets" => 50
    },
    "events_default" => 0,
    "historical" => 100,
    "invite" => 0,
    "kick" => 50,
    "redact" => 50,
    "state_default" => 50,
    "users_default" => 0
  }

  def find_or_create_state_key(state_key) do
    event_state_key = get_event_state_key(state_key)

    if event_state_key do
      {:ok, event_state_key}
    else
      create_state_key(state_key)
    end
  end

  def get_event_state_key(state_key) do
    from(esk in EventStateKey, where: esk.state_key == ^state_key)
    |> Repo.one()
  end

  def create_state_key(state_key) do
    %EventStateKey{}
    |> EventStateKey.changeset(%{"state_key" => state_key})
    |> Repo.insert()
  end

  @doc """
  Returns the list of events.

  ## Examples

      iex> list_events()
      [%Event{}, ...]

  """
  def list_events do
    Repo.all(Event)
  end

  @doc """
  Gets a single event.

  Raises `Ecto.NoResultsError` if the Event does not exist.

  ## Examples

      iex> get_event!(123)
      %Event{}

      iex> get_event!(456)
      ** (Ecto.NoResultsError)

  """
  def get_event!(id), do: Repo.get!(Event, id)

  @doc """
  Creates a event.

  ## Examples

      iex> create_event(%{field: value})
      {:ok, %Event{}}

      iex> create_event(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_event(attrs, "m.room.power_levels", depth) do
    {:ok, event_state_key} = find_or_create_state_key("")
    sender = Map.fetch!(attrs, "sender")

    attrs
    |> Map.merge(%{
      "depth" => depth,
      "type" => "m.room.power_levels",
      "state_key" => event_state_key.state_key,
      "content" =>
        Map.merge(
          Map.put(@default_power_levels, "users", %{sender => 100}),
          Map.get(attrs, "power_level_content_override", %{})
        )
    })
    |> create_event()
  end

  def create_event(attrs, "initial_state", depth) do
    {:ok, event_state_key} = Map.get(attrs, "event_state_key", "")

    Map.merge(attrs, %{"state_key" => event_state_key.state_key, "depth" => depth})
    |> create_event()
  end

  def create_event(params, "m.room.create") do
    {:ok, event_state_key} = find_or_create_state_key("")

    Map.merge(params, %{
      "state_key" => event_state_key.state_key,
      "depth" => 1,
      "auth_event_ids" => [],
      "content" =>
        Map.get(params, "content_creation", %{})
        |> Map.merge(%{
          "creator" => Map.fetch!(params, "sender")
        }),
      "type" => "m.room.create",
      "room_id" => Map.fetch!(params, "room_id")
    })
    |> create_event()
  end

  def create_event(attrs, "m.room.member", membership, depth) do
    {:ok, event_state_key} = Map.fetch!(attrs, "event_state_key") |> find_or_create_state_key()

    attrs
    |> Map.merge(%{
      "depth" => depth,
      "state_key" => event_state_key.state_key,
      "type" => "m.room.member",
      "content" => %{
        "membership" => membership
      }
    })
    |> create_event()
  end

  def create_event(attrs, "m.room.join_rules", join_rule, depth) do
    {:ok, event_state_key} = find_or_create_state_key("")

    attrs
    |> Map.merge(%{
      "depth" => depth,
      "type" => "m.room.join_rules",
      "state_key" => event_state_key.state_key,
      "content" =>
        Map.merge(
          %{
            "join_rule" => join_rule
          },
          Map.get(attrs, "content", %{})
        )
    })
    |> create_event()
  end

  def create_event(attrs, "m.room.history_visibility", visibility, depth) do
    {:ok, event_state_key} = find_or_create_state_key("")

    attrs
    |> Map.merge(%{
      "depth" => depth,
      "type" => "m.room.history_visibility",
      "state_key" => event_state_key.state_key,
      "content" => %{
        "history_visibility" => visibility
      }
    })
    |> create_event()
  end

  def create_event(attrs, "m.room.guest_access", access, depth) do
    {:ok, event_state_key} = find_or_create_state_key("")

    attrs
    |> Map.merge(%{
      "depth" => depth,
      "type" => "m.room.guest_access",
      "state_key" => event_state_key.state_key,
      "content" => %{
        "guest_access" => access
      }
    })
    |> create_event()
  end

  def create_event(attrs \\ %{}) do
    %Event{}
    |> Event.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a event.

  ## Examples

      iex> update_event(event, %{field: new_value})
      {:ok, %Event{}}

      iex> update_event(event, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_event(%Event{} = event, attrs) do
    event
    |> Event.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a event.

  ## Examples

      iex> delete_event(event)
      {:ok, %Event{}}

      iex> delete_event(event)
      {:error, %Ecto.Changeset{}}

  """
  def delete_event(%Event{} = event) do
    Repo.delete(event)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking event changes.

  ## Examples

      iex> change_event(event)
      %Ecto.Changeset{data: %Event{}}

  """
  def change_event(%Event{} = event, attrs \\ %{}) do
    Event.changeset(event, attrs)
  end
end
