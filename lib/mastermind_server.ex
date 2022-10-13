defmodule MastermindServer do
  @moduledoc """
  Starts a server which listens on a port for an incoming
  client connection on that port, then accepts the connection.
  The server reads the data (guess) from the client,
  and returns a response according to the rules of Mastermind.
  """

  require Logger

  alias MastermindServer.Play

  def accept(port) do
    # The options below mean:
    #
    # 1. `:binary` - receives data as binaries (instead of lists)
    # 2. `packet: :line` - receives data line by line
    # 3. `active: false` - blocks on `:gen_tcp.recv/2` until data is available
    # 4. `reuseaddr: true` - allows us to reuse the address if the listener crashes
    #
    {:ok, socket} =
      :gen_tcp.listen(port, [:binary, packet: :line, active: false, reuseaddr: true])
    Logger.info("Accepting connections on port #{port}")

    Play.pick_colors()
    |> IO.inspect()
    |> loop_acceptor(socket)
  end

  defp loop_acceptor(correct_colors, socket) do
    {:ok, client} = :gen_tcp.accept(socket)
    {:ok, pid} = Task.Supervisor.start_child(MastermindServer.TaskSupervisor, fn -> serve(client, correct_colors) end)
    :ok = :gen_tcp.controlling_process(client, pid)
    loop_acceptor(correct_colors, socket)
  end

  defp serve(socket, correct_colors) do
    msg =
      with {:ok, data} <- read_line(socket),
           {:ok, guess_list} <- MastermindServer.Play.parse(data),
           do: MastermindServer.Play.grade(guess_list, correct_colors)

    write_line(socket, msg)
    close_connection?(socket, correct_colors, msg)
  end

  defp read_line(socket) do
    :gen_tcp.recv(socket, 0)
  end

  defp write_line(socket, {:ok, text}) do
    :gen_tcp.send(socket, text)
  end

  defp write_line(socket, {:error, :not_found}) do
    :gen_tcp.send(socket, "NOT FOUND\r\n")
  end

  defp write_line(socket, {:error, :unknown_command}) do
    # Known error. Write to the client.
    :gen_tcp.send(socket, "UNKNOWN COMMAND\r\n")
  end

  defp write_line(_socket, {:error, :closed}) do
    # The connection was closed, exit politely.
    exit(:shutdown)
  end

  defp write_line(socket, {:error, error}) do
    # Unknown error. Write to the client and exit.
    :gen_tcp.send(socket, "ERROR\r\n")
    exit(error)
  end

  defp close_connection?(socket, colors, {:ok, "4 4\r\n"}) do
    exit(:shutdown)
  end
  defp close_connection?(socket, correct_colors, _tuple) do
    serve(socket, correct_colors)
  end
end
