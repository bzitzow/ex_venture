defmodule Web.RoomTest do
  use Data.ModelCase

  alias Web.Room
  alias Web.Zone

  setup do
    {:ok, zone} = Zone.create(%{name: "The Forest"})
    %{zone: zone}
  end

  test "creating a new room adds a child to the room supervision tree", %{zone: zone} do
    params = %{
      name: "Forest Path",
      description: "A small forest path",
      x: 1,
      y: 1,
    }

    {:ok, room} = Room.create(zone, params)
    assert room.name == "Forest Path"

    state = Game.Zone._get_state(zone.id)
    children = state.room_supervisor_pid |> Supervisor.which_children()
    assert children |> length() == 1
  end

  test "updating a room updates the room state in the supervision tree", %{zone: zone} do
    params = %{
      name: "Forest Path",
      description: "A small forest path",
      x: 1,
      y: 1,
    }

    {:ok, room} = Room.create(zone, params)
    {:ok, room} = Room.update(room.id, %{name: "Pathway"})
    assert room.name == "Pathway"

    # Check the supervision tree to make sure casts have gone through
    state = Game.Zone._get_state(zone.id)
    children = state.room_supervisor_pid |> Supervisor.which_children()
    assert children |> length() == 1

    state = Game.Room._get_state(room.id)
    assert state.room.name == "Pathway"
  end

  test "adding an item to a room", %{zone: zone} do
    params = %{name: "Forest Path", description: "A small forest path", x: 1, y: 1}
    {:ok, room} = Room.create(zone, params)
    item = create_item()
    {:ok, room} = Room.add_item(room, item.id)

    state = Game.Room._get_state(room.id)
    assert state.room.item_ids |> length() == 1
  end

  test "create a room item", %{zone: zone} do
    params = %{name: "Forest Path", description: "A small forest path", x: 1, y: 1}
    {:ok, room} = Room.create(zone, params)
    item = create_item()
    {:ok, room} = Room.update(room.id, %{name: "Pathway"})

    {:ok, _room_item} = Room.create_item(room, %{item_id: item.id, spawn_interval: 15})

    state = Game.Room._get_state(room.id)
    assert state.room.room_items |> length() == 1
  end

  test "delete room item", %{zone: zone} do
    params = %{name: "Forest Path", description: "A small forest path", x: 1, y: 1}
    {:ok, room} = Room.create(zone, params)
    item = create_item()
    room_item = create_room_item(room, item, %{spawn_interval: 15})
    {:ok, room} = Room.update(room.id, %{name: "Pathway"})

    {:ok, _room_item} = Room.delete_item(room_item.id)

    state = Game.Room._get_state(room.id)
    assert state.room.room_items |> length() == 0
  end
end
