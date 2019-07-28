defmodule TimestampedProcess do
  @moduledoc """
  Implement a process that keeps time in a distributed system via
  a Vector Clock.
  """
  use GenServer

  # Client API
  def start_link(%{name: name} = args) do
    GenServer.start_link(__MODULE__, args, name: {:global, name})
  end

  def send_from(a, b, msg) do
    GenServer.call(a, {:send_message, b, msg})
  end

  # Server Implementation
  def init(%{name: name} = state) do
    state = Map.put_new(state, :clock, %{name => 0})
    {:ok, state}
  end

  def handle_call(:get_clock, _from, state) do
    {:reply, {:ok, state.clock}, state}
  end

  def handle_call({:send_message, to, msg}, _from, state) do
    new_clock = Map.update!(state.clock, state.name, &(&1 + 1))
    message_with_clock = %{message: msg, remote_vector: new_clock}
    new_state = %{state | clock: new_clock}
    # new_state = Map.merge(state, msg.vector, fn _k, v1, v2 -> Kernel.max(v1, v2) end)
    Process.send(to, {:receive, message_with_clock}, [])
    {:reply, {:ok, new_state}, new_state}
  end

  def handle_info({:receive, %{message: msg, remote_vector: remote_vector}}, state) do
    new_clock =
      remote_vector
      |> Map.merge(state.clock, fn _k, c1, c2 -> Kernel.max(c1, c2) end)
      |> Map.update!(state.name, &(&1 + 1))

    new_state = %{state | clock: new_clock}
    {:noreply, new_state}
  end
end
