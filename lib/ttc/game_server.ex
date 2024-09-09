defmodule Ttc.GameServer do
  use GenServer
  require Logger

  @win_conditions [
    # Rows
    [0, 1, 2],
    [3, 4, 5],
    [6, 7, 8],
    # Columns
    [0, 3, 6],
    [1, 4, 7],
    [2, 5, 8],
    # Diagonals
    [0, 4, 8],
    [2, 4, 6]
  ]

  def start_link(state, name) do
    GenServer.start_link(__MODULE__, state, name: name)
  end

  def start_game(game_id) do
    GenServer.call(via_tuple(game_id), :start_game)
  end

  def restart_game(game_id) do
    GenServer.call(via_tuple(game_id), :restart_game)
  end

  def make_move(game_id, username, x, y) do
    GenServer.call(via_tuple(game_id), {:make_move, username, x, y})
  end

  def add_player(game_id, username) do
    GenServer.call(via_tuple(game_id), {:add_player, username})
  end

  def remove_player(game_id, username) do
    GenServer.call(via_tuple(game_id), {:remove_player, username})
  end

  def get_state(game_id) do
    GenServer.call(via_tuple(game_id), :get_game_state)
  end

  def init(state), do: {:ok, state}

  def handle_call(
        {:make_move, username, x, y},
        _from,
        %{current_player: username, status: "started"} = state
      ) do
    new_state = apply_move(state, x, y, username)

    winner = get_winner_if_exists(new_state.board)

    # TODO: handle when board is already filled in the required position
    new_state =
      if winner != nil do
        %{new_state | status: "finished", winner: new_state[:players][winner]}
      else
        has_finished =
          state.board
          |> List.flatten()
          |> Enum.all?(fn elem -> elem != "" end)

        %{new_state | status: if(has_finished, do: "finished", else: state.status)}
      end

    {:reply, {:ok, new_state}, new_state}
  end

  def handle_call({:make_move, _, _, _}, _from, state) do
    error_message =
      cond do
        state.status == "finished" ->
          :game_already_finished

        state.status == "waiting" ->
          :game_not_started

        true ->
          :wait_for_your_turn
      end

    {:reply, {:error, error_message}, state}
  end

  def handle_call(:start_game, _from, %{player_1: player_1, player_2: player_2} = state)
      when is_nil(player_1) or is_nil(player_2) do
    {:reply, {:error, :cannot_start_game}, state}
  end

  def handle_call(:start_game, _from, state) do
    %{player_1: player_1, player_2: player_2} = state
    first_player = [player_1, player_2] |> Enum.shuffle() |> hd

    state = %{
      state
      | status: "started",
        current_player: first_player,
        players: %{"X" => player_1, "O" => player_2}
    }

    {:reply, {:ok, state}, state}
  end

  def handle_call(:restart_game, _from, state) do
    new_state = %{
      initial_game_state(state.game_id)
      | player_1: state.player_1,
        player_2: state.player_2,
        players: state.players
    }

    {:reply, new_state, new_state}
  end

  def handle_call({:add_player, player}, _from, %{player_1: player} = state),
    do: {:reply, {:error, :you_already_joined}, state}

  def handle_call({:add_player, player}, _from, %{player_2: player} = state),
    do: {:reply, {:error, :you_already_joined}, state}

  def handle_call({:add_player, player}, _from, %{player_1: player_1, player_2: player_2} = state) do
    result =
      case {player_1, player_2} do
        {nil, _} -> {:ok, %{state | player_1: player}}
        {_, nil} -> {:ok, %{state | player_2: player}}
        _ -> {:error, :game_server_already_full}
      end

    case result do
      {:ok, new_state} -> {:reply, result, new_state}
      {:error, _} -> {:reply, result, state}
    end
  end

  def handle_call({:remove_player, username}, _from, state) do
    %{player_1: player_1, player_2: player_2} = state

    new_state =
      cond do
        player_1 == username ->
          %{state | player_1: player_2, player_2: nil}

        player_2 == username ->
          %{state | player_2: nil}

        true ->
          state
      end

    if new_state.player_1 == nil && new_state.player_2 == nil do
      Process.send_after(self(), :terminate, 1000)
      Logger.info("Terminating game with #{state.game_id}")
      {:reply, {:ok, :game_ended}, new_state}
    else
      {:reply, {:ok, new_state}, new_state}
    end
  end

  def handle_call(:get_game_state, _from, state) do
    {:reply, state, state}
  end

  def handle_info(:terminate, state) do
    {:stop, :normal, state}
  end

  def initial_game_state(game_id) do
    %{
      player_1: nil,
      player_2: nil,
      game_id: game_id,
      board: [
        ["", "", ""],
        ["", "", ""],
        ["", "", ""]
      ],
      status: "waiting",
      players: %{
        "X" => nil,
        "O" => nil
      },
      current_player: nil,
      winner: nil
    }
  end

  defp apply_move(%{board: board} = game_state, x, y, username) do
    board =
      game_state
      |> get_player_symbol(username)
      |> change_board(board, x, y)

    %{
      game_state
      | board: board,
        current_player:
          if(game_state.player_1 == username, do: game_state.player_2, else: game_state.player_1)
    }
  end

  defp get_player_symbol(game_state, username) do
    cond do
      game_state.players["X"] == username -> "X"
      game_state.players["O"] == username -> "O"
      true -> ""
    end
  end

  defp change_board(symbol, board, x, y) do
    board
    |> Enum.with_index()
    |> Enum.map(fn {original_elem, row} ->
      if row == y do
        original_elem
        |> Enum.with_index()
        |> Enum.map(fn {elem, col} ->
          if col == x do
            symbol
          else
            elem
          end
        end)
      else
        original_elem
      end
    end)
  end

  defp get_winner_if_exists(board) do
    flat_board = List.flatten(board)

    Enum.find_value(@win_conditions, fn [a, b, c] ->
      if Enum.at(flat_board, a) != "" and
           Enum.at(flat_board, a) == Enum.at(flat_board, b) and
           Enum.at(flat_board, b) == Enum.at(flat_board, c) do
        Enum.at(flat_board, a)
      end
    end)
  end

  defp via_tuple(game_id) do
    {:via, Registry, {Ttc.Registry, game_id}}
  end
end
