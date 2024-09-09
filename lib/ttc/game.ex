defmodule Ttc.Game do
  @base32_chars "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"
  @game_id_length 4

  def generate_game_id do
    generate(@game_id_length)
  end

  defp generate(length)
       when is_integer(length) and
              length > 0 do
    1..length
    |> Enum.map(fn _ -> random_base32_char() end)
    |> Enum.join()
  end

  defp random_base32_char do
    @base32_chars
    |> String.split("", trim: true)
    |> Enum.random()
  end
end
