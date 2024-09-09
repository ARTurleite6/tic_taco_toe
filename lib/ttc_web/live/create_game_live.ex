defmodule TtcWeb.CreateGameLive do
  use TtcWeb, :live_view
  alias Ttc.Game
  alias Ttc.GameManager
  alias Ttc.GameServer

  def mount(_params, _session, socket) do
    {:ok, assign(socket, :form, to_form(%{"username" => ""}, as: "user"))}
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gradient-to-r from-blue-500 to-purple-600 flex flex-col justify-center items-center p-4">
      <div class="max-w-md w-full bg-white shadow-2xl rounded-lg overflow-hidden">
        <div class="px-8 py-10">
          <h1 class="text-4xl font-extrabold text-center text-gray-800 mb-8">Create a New Game</h1>

          <.simple_form :let={f} for={@form} phx-submit="create_game" class="space-y-6">
            <.input
              field={f[:username]}
              type="text"
              label="Your Name"
              placeholder="Enter your name"
              required
              class="w-full px-4 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500"
            />

            <.button class="w-full bg-indigo-600 hover:bg-indigo-700 text-white font-bold py-3 px-4 rounded-lg transition duration-300">
              Create Game
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

  def handle_event("create_game", %{"username" => username}, socket) do
    game_id = Game.generate_game_id()

    socket = with {:ok, _} <- GameManager.start_game(game_id),
         {:ok, _} <- GameServer.add_player(game_id, username) do
      socket
      |> put_flash(:info, "Game successfully started")
      |> push_navigate(to: ~p"/game/#{game_id}/#{username}")
    else
      {:error, :game_already_started} ->
        put_flash(socket, :error, "This session already exists")
    end

    {:noreply, socket}
  end
end
