defmodule MastermindServer.Play do
  @moduledoc false

  @list_size 4
  @number_of_colors 6

  @doc """
    Picks random colors for the game
  """
  def pick_colors() do
    Enum.flat_map(1..@list_size, fn(_) -> Enum.take_random(0..@number_of_colors - 1, 1) end)
  end

  @doc """
    Parses the incoming data string
  """
  def parse(nil), do: {:error, "No data found\r\n"}
  def parse(""), do: {:error, "No data found\r\n"}
  def parse(line) do
     data = String.split(line)
     |> Enum.map(fn(x) -> String.to_integer(x) end)

     {:ok, data}
  end

  @doc """
    Checks the user list against the correct colors,
    returning number of correct colors and number in the correct place.
    """
  def grade(guess, correct_colors) when is_list(guess) and length(guess) == @list_size do
    do_grade(guess, correct_colors)
    |> return_score()
  end
  def grade(_guess, _correct_colors) do
    {:ok, "Please enter four numbers between 0 and 5, with a space between each number.\r\n"}
  end

  defp do_grade(list, colors) do
    acc_map = %{
      all_colors: colors,
      member_list: colors,
      num_members: 0,
      num_in_position: 0
    }

    list
    |> Enum.with_index
    |> Enum.reduce(acc_map, fn({x, idx}, acc) ->
      color_at_position = Enum.at(acc.all_colors, idx)

      color_membership(acc, x)
      |> check_position(x, color_at_position)
    end)
  end

  defp color_membership(acc, x) do
    do_color_membership(acc, x, acc.member_list)
  end

  defp do_color_membership(acc, x, []), do: acc
  defp do_color_membership(acc, x, [hd | tail]) do
    case x do
      ^hd ->
        %{acc | member_list: List.delete(acc.member_list, x), num_members: acc.num_members + 1}
      _ ->
        do_color_membership(acc, x, tail)
    end
  end

  defp check_position(acc, x, color_at_position) when x == color_at_position do
    %{acc | num_in_position: acc.num_in_position + 1}
  end
  defp check_position(acc, _x, _color_at_position), do: acc

  defp return_score(acc) do
    {:ok, "#{acc.num_members} #{acc.num_in_position}\r\n"}
  end
end
