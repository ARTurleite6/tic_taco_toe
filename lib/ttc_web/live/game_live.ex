defmodule TtcWeb.GameLive do
  use TtcWeb, :live_view
  alias Ttc.GameServer

  def mount(%{"game_id" => game_id, "username" => username}, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Ttc.PubSub, "game:#{game_id}")
    end

    {
      :ok,
      socket
      |> assign(:username, username)
      |> assign(:game_id, game_id)
      |> assign(:game, GameServer.get_state(game_id))
    }
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-2xl mx-auto p-6 bg-gray-100 rounded-lg shadow-md">
      <%= if @game.status == "finished" do %>
        <%= for _ <- 1..50 do %>
          <div
            class="confetti"
            style={"left: #{:rand.uniform(100)}%; animation-delay: #{:rand.uniform(4000)}ms;"}
          >
          </div>
        <% end %>
      <% end %>
      <div class="mb-6 text-center">
        <p class="text-lg font-semibold mb-2">Game Room Code:</p>
        <div class="flex items-center justify-center">
          <span id="game-code" class="text-2xl font-bold text-indigo-600 mr-2"><%= @game_id %></span>
          <button
            phx-click={JS.dispatch("phx:copy", to: "#game-code")}
            class="bg-gray-200 hover:bg-gray-300 rounded-full p-2 focus:outline-none focus:ring-2 focus:ring-indigo-500"
          >
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="h-6 w-6 text-gray-600"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M8 5H6a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2v-1M8 5a2 2 0 002 2h2a2 2 0 002-2M8 5a2 2 0 012-2h2a2 2 0 012 2m0 0h2a2 2 0 012 2v3m2 4H10m0 0l3-3m-3 3l3 3"
              />
            </svg>
          </button>
        </div>
      </div>

      <div class={
        "text-center p-4 rounded-md mb-6 " <>
        case @game.status do
          "waiting" -> "bg-yellow-200"
          "started" -> "bg-green-200"
          "finished" -> "bg-blue-200"
        end
      }>
        <%= case @game.status do %>
          <% "waiting" -> %>
            <div class="text-4xl mb-2">⏳</div>
            <h2 class="text-xl font-bold">Waiting for players</h2>
          <% "started" -> %>
            <div class="text-4xl mb-2">🏁</div>
            <h2 class="text-xl font-bold">Game in progress</h2>
          <% "finished" -> %>
            <div class="text-4xl mb-2">🏆</div>
            <h2 class="text-xl font-bold">Game finished</h2>
            <%= if @game.winner do %>
              <p class="mt-2 text-lg">Winner: <span class="font-bold"><%= @game.winner %></span></p>
            <% else %>
              <p class="mt-2 text-lg">It's a draw!</p>
            <% end %>
            <%= if @username == @game.player_1 do %>
              <button
                phx-click="restart_game"
                class="mt-4 bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded"
              >
                Restart Game
              </button>
            <% end %>
        <% end %>
      </div>

      <div class="flex justify-around items-center mb-6">
        <div class={
          "text-center p-3 rounded-md " <>
          if @game.current_player == @game.player_1, do: "bg-blue-200 font-bold", else: "bg-gray-200"
        }>
          <div class="w-16 h-16 bg-gray-300 rounded-full flex items-center justify-center mb-2 mx-auto">
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="h-10 w-10 text-gray-600"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"
              />
            </svg>
          </div>
          <span><%= @game.player_1 || "Waiting..." %></span>
          <%= if @game.player_1 do %>
            <div class="mt-2 text-2xl font-bold">
              <%= get_player_symbol(@game, @game.player_1) %>
            </div>
          <% end %>
        </div>
        <div class="font-bold text-xl">VS</div>
        <div class={
          "text-center p-3 rounded-md " <>
          if @game.current_player == @game.player_2, do: "bg-blue-200 font-bold", else: "bg-gray-200"
        }>
          <div class="w-16 h-16 bg-gray-300 rounded-full flex items-center justify-center mb-2 mx-auto">
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="h-10 w-10 text-gray-600"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"
              />
            </svg>
          </div>
          <span><%= @game.player_2 || "Waiting..." %></span>
          <%= if @game.player_2 do %>
            <div class="mt-2 text-2xl font-bold">
              <%= get_player_symbol(@game, @game.player_2) %>
            </div>
          <% end %>
        </div>
      </div>

      <%= if can_start_game?(@game, @username) do %>
        <div class="mb-6 text-center">
          <button
            phx-click="start_game"
            class="bg-green-500 hover:bg-green-700 text-white font-bold py-2 px-4 rounded"
          >
            Start Game
          </button>
        </div>
      <% end %>

      <div class="flex justify-center items-center mt-6">
        <div class="border-2 border-gray-800 inline-block rounded-md overflow-hidden">
          <%= for {row, row_index} <- Enum.with_index(@game.board) do %>
            <div class="flex">
              <%= for {cell, col_index} <- Enum.with_index(row) do %>
                <div
                  class="w-20 h-20 flex justify-center items-center text-4xl border border-gray-400 cursor-pointer hover:bg-gray-200 transition-colors duration-300"
                  phx-click="make_move"
                  phx-value-row={row_index}
                  phx-value-col={col_index}
                >
                  <%= case cell do %>
                    <% "X" -> %>
                      <span>❌</span>
                    <% "O" -> %>
                      <span>⭕</span>
                    <% _ -> %>
                      <span></span>
                  <% end %>
                </div>
              <% end %>
            </div>
          <% end %>
        </div>
      </div>
      <div class="m-6 text-center">
        <button
          phx-click="leave_game"
          class="bg-red-500 hover:bg-red-700 text-white font-bold py-2 px-4 rounded"
        >
          Leave Game
        </button>
      </div>
    </div>
    """
  end

  def handle_event("make_move", %{"row" => row, "col" => col}, socket) do
    username = socket.assigns.username
    game_id = socket.assigns.game_id

    socket =
      case GameServer.make_move(game_id, username, String.to_integer(col), String.to_integer(row)) do
        {:ok, new_game_state} ->
          Phoenix.PubSub.broadcast(Ttc.PubSub, "game:#{game_id}", :player_move)

          socket
          |> assign(:game, new_game_state)
          |> put_flash(:info, "Move played successfully #{inspect({row, col})}")

        {:error, :game_already_finished} ->
          socket
          |> put_flash(:error, "The game has finished")

        {:error, :game_not_started} ->
          socket
          |> put_flash(:error, "You need to wait for the game to start")

        {:error, :wait_for_your_turn} ->
          socket
          |> put_flash(:error, "You need to wait for your turn to make a move")
      end

    {:noreply, socket}
  end

  def handle_event("leave_game", _params, socket) do
    game_id = socket.assigns.game_id
    username = socket.assigns.username

    leave_game(game_id, username)

    socket =
      socket
      |> put_flash(:info, "Leaving game...")
      |> push_navigate(to: "/")

    {:noreply, socket}
  end

  def handle_event("start_game", _params, socket) do
    game_id = socket.assigns.game_id

    socket =
      case GameServer.start_game(game_id) do
        {:ok, new_game_state} ->
          Phoenix.PubSub.broadcast(Ttc.PubSub, "game:#{game_id}", :game_started)

          socket
          |> assign(:game, new_game_state)
          |> put_flash(:info, "Game successfully started")

        {:error, :cannot_start_game} ->
          socket
          |> put_flash(:error, "There needs to be at least two players to continue")

          nil
      end

    {:noreply, socket}
  end

  def handle_event("restart_game", _params, socket) do
    GameServer.restart_game(socket.assigns.game_id)
    Phoenix.PubSub.broadcast(Ttc.PubSub, "game:#{socket.assigns.game_id}", :game_restarted)
    {:noreply, restart_game(socket)}
  end

  def handle_info(:game_restarted, socket) do
    {:noreply, restart_game(socket)}
  end

  def handle_info({:player_joined, username}, socket) do
    {:noreply, list_player_update(socket, "#{username} joined the game")}
  end

  def handle_info({:player_left, username}, socket) do
    {:noreply, list_player_update(socket, "#{username} left the game")}
  end

  def handle_info(:game_started, socket) do
    {:noreply,
     socket
     |> assign(:game, GameServer.get_state(socket.assigns.game_id))
     |> put_flash(:info, "Game started by game owner")}
  end

  def handle_info(:player_move, socket) do
    {:noreply, assign(socket, :game, GameServer.get_state(socket.assigns.game_id))}
  end

  defp list_player_update(socket, message) do
    socket
    |> put_flash(:info, message)
    |> assign(:game, GameServer.get_state(socket.assigns.game_id))
  end

  defp leave_game(game_id, username) do
    GameServer.remove_player(game_id, username)

    Phoenix.PubSub.broadcast(
      Ttc.PubSub,
      "game:#{game_id}",
      {:player_left, username}
    )

    Phoenix.PubSub.unsubscribe(Ttc.PubSub, "game:#{game_id}")
  end

  defp restart_game(socket) do
    socket
    |> assign(:game, GameServer.get_state(socket.assigns.game_id))
    |> put_flash(:info, "Game restarted")
  end

  defp can_start_game?(game, username) do
    game.status == "waiting" && game.player_1 == username && game.player_2 != nil
  end

  defp get_player_symbol(game, username) do
    cond do
      game.players["X"] == username -> "X"
      game.players["O"] == username -> "⭕"
      true -> ""
    end
  end
end
