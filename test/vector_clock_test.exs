defmodule VectorClockTest do
  use ExUnit.Case

  describe "Vector Clock Conditions" do
    setup do
      names = [:one, :two, :three, :four]

      pids =
        Enum.map(names, fn name ->
          {:ok, pid} = VectorClock.start_link(%{name: name})
          pid
        end)

      {:ok, pids: pids}
    end

    @tag :skip
    test "All clocks at initialized at 0", %{pids: pids} do
      sum_of_all_clocks =
        pids
        |> Enum.flat_map(fn pid ->
          {:ok, clock} = GenServer.call(pid, :get_clock)
          clock
        end)
        |> Enum.reduce(0, fn {_k, v}, acc ->
          v + acc
        end)

      assert sum_of_all_clocks == 0
    end

    @tag :skip
    test "Sending a message increments senders clock by 1", %{pids: pids} do
      [p1 | [p2 | _pids]] = pids
      VectorClock.send_from(p1, p2, "boop")
      {:ok, first_clock} = GenServer.call(p1, :get_clock)
      # In the sending process, the clock for the sending process should increment.
      assert first_clock[:one] == 1
    end

    @tag :skip
    test "Receiving a message increments receiver's clock by 1", %{pids: pids} do
      [p1 | [p2 | _pids]] = pids
      VectorClock.send_from(p1, p2, "boop")
      {:ok, second_clock} = GenServer.call(p2, :get_clock)
      # In the receiving process, the clock for the sending process should increment.
      assert second_clock[:two] == 1
    end

    @tag :skip
    test "Receiver merges its vector clock with senders", %{
      pids: pids
    } do
      [p1 | [p2 | _pids]] = pids
      {:ok, second_clock} = GenServer.call(p2, :get_clock)
      # Process two hasn't yet heard from process one, and doesn't know its clock value.
      refute Map.has_key?(second_clock, :one)
      VectorClock.send_from(p1, p2, "boop")
      {:ok, second_clock} = GenServer.call(p2, :get_clock)
      # In the receiving process, the clock for the sending process should increment.
      assert second_clock[:one] == 1
      assert second_clock[:two] == 1
      # First clock still hasn't heard from process two, but is aware of its own clock
      {:ok, first_clock} = GenServer.call(p1, :get_clock)
      assert first_clock[:one] == 1
      refute Map.has_key?(first_clock, :two)
    end

    @tag :skip
    test "Receiver merges its vector clock with senders, taking the max value", %{
      pids: pids
    } do
      [p1, p2, p3, _p4] = pids
      # Here we diverge process state between p1, p2, and p3.
      VectorClock.send_from(p1, p2, "boop")
      Enum.each(1..10, fn _ -> VectorClock.send_from(p1, p3, "boop") end)
      {:ok, p2_clock} = GenServer.call(p2, :get_clock)
      assert p2_clock[:one] == 1
      # At this point, our third clock knows that Clock(P1) = 1
      # but our second process has only seen the very first message from process 1.
      {:ok, p3_clock} = GenServer.call(p3, :get_clock)
      assert p3_clock[:one] == 11
      # Even though process 1 doesn't directly communicate with process 2,
      # when P3 communicates with P2, P2.Clock(P1) should now be updated at 11.
      VectorClock.send_from(p3, p2, "boop")
      {:ok, p2_clock} = GenServer.call(p2, :get_clock)
      assert p2_clock[:one] == 11
    end
  end
end
