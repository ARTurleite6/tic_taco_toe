defmodule TtcWeb.HomeLive do
  use TtcWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-100 flex flex-col justify-center items-center">
      <div class="max-w-md w-full bg-white shadow-lg rounded-lg overflow-hidden">
        <div class="px-6 py-8">
          <h1 class="text-3xl font-bold text-center text-gray-800 mb-8">Welcome to Game Hub</h1>

          <div class="space-y-4">
            <button
              phx-click={JS.navigate(~p"/create")}
              class="w-full bg-blue-500 hover:bg-blue-600 text-white font-bold py-3 px-4 rounded-lg transition duration-300 flex items-center justify-center"
            >
              <svg
                xmlns="http://www.w3.org/2000/svg"
                class="h-6 w-6 mr-2"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M12 6v6m0 0v6m0-6h6m-6 0H6"
                />
              </svg>
              Create New Game
            </button>

            <button
              phx-click={JS.navigate(~p"/join")}
              class="w-full bg-green-500 hover:bg-green-600 text-white font-bold py-3 px-4 rounded-lg transition duration-300 flex items-center justify-center"
            >
              <svg
                xmlns="http://www.w3.org/2000/svg"
                class="h-6 w-6 mr-2"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M11 16l-4-4m0 0l4-4m-4 4h14m-5 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h7a3 3 0 013 3v1"
                />
              </svg>
              Join Existing Game
            </button>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
