defmodule TtcWeb.JoinGameLive do
  use TtcWeb, :live_view
  alias Ttc.GameManager
  alias Ttc.GameServer

  def mount(_params, _session, socket) do
    {:ok, assign(socket, :form, to_form(%{username: "", game_id: ""}))}
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gradient-to-r from-green-500 to-blue-600 flex flex-col justify-center items-center p-4">
      <div class="max-w-md w-full bg-white shadow-2xl rounded-lg overflow-hidden">
        <div class="px-8 py-10">
          <h1 class="text-4xl font-extrabold text-center text-gray-800 mb-8">Join a Game</h1>

          <.simple_form :let={f} for={@form} phx-submit="join_game" class="space-y-6">
            <.input
              field={f[:username]}
              type="text"
              label="Your Name"
              placeholder="Enter your name"
              required
              class="w-full px-4 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500"
            />
            <.input
              field={f[:game_id]}
              type="text"
              label="Game ID"
              placeholder="Enter the game ID"
              required
              class="w-full px-4 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500"
            />

            <.button class="w-full bg-indigo-600 hover:bg-indigo-700 text-white font-bold py-3 px-4 rounded-lg transition duration-300">
              Join Game
            </.button>
          </.simple_form>

          <div class="mt-6 text-center">
            <.link navigate={~p"/"} class="text-indigo-600 hover:text-indigo-800 font-medium">
              Back to Home
            </.link>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def handle_event("join_game", %{"username" => username, "game_id" => game_id}, socket) do
    socket =
      if GameManager.exist_game?(game_id) do
        case GameServer.add_player(game_id, username) do
          {:ok, _} ->
            Phoenix.PubSub.broadcast(Ttc.PubSub, "game:#{game_id}", {:player_joined, username})

            socket
            |> put_flash(:info, "Joining game with id #{game_id}")
            |> push_navigate(to: ~p"/game/#{game_id}/#{username}")

          {:error, _} ->
            socket
            |> put_flash(:error, "Game with id #{game_id} is already full")
        end
      else
        socket
        |> put_flash(:error, "Game with id #{game_id} does not exist")
      end

    {:noreply, socket}
  end
end
