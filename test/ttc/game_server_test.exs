defmodule Ttc.GameServerTest do
  use ExUnit.Case, async: true

  alias Ttc.GameServer

  setup do
    game_id = "test_game"

    {:ok, _pid} =
      GameServer.start_link(
        GameServer.initial_game_state(game_id),
        {:via, Registry, {Ttc.Registry, game_id}}
      )

    %{game_id: game_id}
  end

  test "initial_game_state", %{game_id: game_id} do
    state = GameServer.get_state(game_id)
    assert state.player_1 == nil
    assert state.player_2 == nil
  end

  test "Adding player updates state", %{game_id: game_id} do
    assert {:ok, new_state} = GameServer.add_player(game_id, "first player")

    assert new_state.player_1 != nil

    assert {:ok, new_state} = GameServer.add_player(game_id, "second player")
    assert new_state.player_2 != nil
  end

  test "returns error if adding a player twice", %{game_id: game_id} do
    GameServer.add_player(game_id, "first player")

    assert {:error, :you_already_joined} = GameServer.add_player(game_id, "first player")
  end

  test "returns error if game is already full", %{game_id: game_id} do
    GameServer.add_player(game_id, "first player")
    GameServer.add_player(game_id, "second player")

    assert {:error, :game_server_already_full} = GameServer.add_player(game_id, "third player")
  end

  test "remove player removes the selected player", %{game_id: game_id} do
    GameServer.add_player(game_id, "first player")
    GameServer.add_player(game_id, "second player")

    assert {:ok, new_state} = GameServer.remove_player(game_id, "second player")
    assert new_state.player_2 == nil
  end

  test "removing admin makes second player the admin", %{game_id: game_id} do
    GameServer.add_player(game_id, "first player")
    GameServer.add_player(game_id, "second player")

    assert {:ok, new_state} = GameServer.remove_player(game_id, "first player")
    assert new_state.player_2 == nil
    assert new_state.player_1 == "second player"
  end

  test "returns error when game has not started", %{game_id: game_id} do
    GameServer.add_player(game_id, "first player")
    GameServer.add_player(game_id, "second player")

    assert {:error, :game_not_started} = GameServer.make_move(game_id, "first player", 0, 0)
  end

  test "should finish if a winning move is made", %{game_id: game_id} do
    GameServer.add_player(game_id, "first player")
    GameServer.add_player(game_id, "second player")
    assert {:ok, state} = GameServer.start_game(game_id)
    assert state.current_player != nil

    first_player = state.current_player

    assert {:ok, state} = GameServer.make_move(game_id, state.current_player, 0, 0)
    assert {:ok, state} = GameServer.make_move(game_id, state.current_player, 0, 1)
    assert {:ok, state} = GameServer.make_move(game_id, state.current_player, 1, 0)
    assert {:ok, state} = GameServer.make_move(game_id, state.current_player, 1, 2)
    assert {:ok, state} = GameServer.make_move(game_id, state.current_player, 2, 0)
    assert state.status == "finished"
    assert state.winner == first_player
  end

  test "making a move places the symbol in the correct place", %{game_id: game_id} do
    GameServer.add_player(game_id, "first player")
    GameServer.add_player(game_id, "second player")
    assert {:ok, state} = GameServer.start_game(game_id)
    assert state.current_player != nil
    current_player = state.current_player

    assert {:ok, state} = GameServer.make_move(game_id, current_player, 0, 0)
    assert state.board |> Enum.at(0) |> Enum.at(0) != ""
  end

  test "return error when making same play twice", %{game_id: game_id} do
    GameServer.add_player(game_id, "first player")
    GameServer.add_player(game_id, "second player")
    assert {:ok, state} = GameServer.start_game(game_id)
    assert state.current_player != nil

    assert {:ok, state} = GameServer.make_move(game_id, state.current_player, 0, 0)

    assert {:error, :play_already_taken} =
             GameServer.make_move(game_id, state.current_player, 0, 0)
  end

  test "finish game when board is full and there was no winner", %{game_id: game_id} do
    GameServer.add_player(game_id, "first player")
    GameServer.add_player(game_id, "second player")
    assert {:ok, state} = GameServer.start_game(game_id)
    assert state.current_player != nil

    assert {:ok, state} = GameServer.make_move(game_id, state.current_player, 0, 0)
    assert {:ok, state} = GameServer.make_move(game_id, state.current_player, 0, 1)
    assert {:ok, state} = GameServer.make_move(game_id, state.current_player, 0, 2)
    assert {:ok, state} = GameServer.make_move(game_id, state.current_player, 1, 2)
    assert {:ok, state} = GameServer.make_move(game_id, state.current_player, 1, 0)
    assert {:ok, state} = GameServer.make_move(game_id, state.current_player, 2, 0)
    assert {:ok, state} = GameServer.make_move(game_id, state.current_player, 1, 1)
    assert {:ok, state} = GameServer.make_move(game_id, state.current_player, 2, 2)

    assert {:ok, %{status: "finished", winner: nil}} =
             GameServer.make_move(game_id, state.current_player, 2, 1)
  end
end
