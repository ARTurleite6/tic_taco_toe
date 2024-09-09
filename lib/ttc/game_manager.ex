defmodule Ttc.GameManager do
  use GenServer
  require Logger
  alias Ttc.GameServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(args) do
    {:ok, args}
  end

  def start_game(game_id) do
    GenServer.call(__MODULE__, {:start_game, game_id})
  end

  def exist_game?(game_id) do
    GenServer.call(__MODULE__, {:exist_game, game_id})
  end

  def handle_call({:exist_game, game_id}, _from, state) do
    {:reply, Registry.lookup(Ttc.Registry, game_id) != [], state}
  end

  def handle_call({:start_game, game_id}, _from, state) do
    Logger.info("Starting game: #{game_id}")

    response =
      case Registry.lookup(Ttc.Registry, game_id) do
        [{_, _pid}] ->
          {:error, :game_already_started}

        [] ->
          {:ok, pid} =
            GameServer.start_link(GameServer.initial_game_state(game_id), via_tuple(game_id))

          {:ok, pid}
      end

    {:reply, response, state}
  end

  defp via_tuple(game_id) do
    {:via, Registry, {Ttc.Registry, game_id}}
  end
end
