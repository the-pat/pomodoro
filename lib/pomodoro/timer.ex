defmodule Pomodoro.Timer do
  use GenServer

  alias __MODULE__.State

  @timeout 100

  def start_link(opts) do
    remaining_milliseconds = Keyword.fetch!(opts, :remaining_milliseconds)
    timer_id = Keyword.fetch!(opts, :timer_id)

    GenServer.start_link(__MODULE__, {:ok, remaining_milliseconds}, name: via_tuple(timer_id))
  end

  def state(timer_id) do
    GenServer.call(via_tuple(timer_id), :state)
  end

  def start(timer_id) do
    GenServer.cast(via_tuple(timer_id), :start)
  end

  def pause(timer_id) do
    GenServer.cast(via_tuple(timer_id), :pause)
  end

  def restart(timer_id) do
    GenServer.cast(via_tuple(timer_id), :restart)
  end

  @impl true
  def init({:ok, remaining_milliseconds}) do
    schedule()

    {:ok, State.new(:paused, remaining_milliseconds)}
  end

  @impl true
  def handle_call(:state, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_cast(:start, %State{state: :paused} = state) do
    {:noreply, %{state | state: :running, last_updated: DateTime.utc_now()}}
  end

  @impl true
  def handle_cast(:start, %State{} = state) do
    {:noreply, %{state | state: :running}}
  end

  @impl true
  def handle_cast(:pause, %State{} = state) do
    {:noreply, %{state | state: :paused, last_updated: DateTime.utc_now()}}
  end

  @impl true
  def handle_cast(:restart, %State{starting_milliseconds: starting_milliseconds} = state) do
    {:noreply,
     %{
       state
       | state: :paused,
         remaining_milliseconds: starting_milliseconds,
         last_updated: DateTime.utc_now()
     }}
  end

  @impl true
  def handle_info(
        :tick,
        %State{state: :running, remaining_milliseconds: remaining_milliseconds} = state
      )
      when remaining_milliseconds <= 0 do
    schedule()

    {:noreply,
     %{state | state: :paused, remaining_milliseconds: 0, last_updated: DateTime.utc_now()}}
  end

  @impl true
  def handle_info(:tick, %State{state: :paused} = state) do
    schedule()

    {:noreply, %{state | last_updated: DateTime.utc_now()}}
  end

  @impl true
  def handle_info(
        :tick,
        %State{remaining_milliseconds: remaining_milliseconds, last_updated: last_updated} = state
      ) do
    schedule()

    now = DateTime.utc_now()

    {:noreply,
     %{
       state
       | remaining_milliseconds:
           remaining_milliseconds - DateTime.diff(now, last_updated, :millisecond),
         last_updated: now
     }}
  end

  defp schedule do
    Process.send_after(self(), :tick, @timeout)
  end

  defp via_tuple(timer_id) do
    {:via, :gproc, {:n, :l, {:timer_id, timer_id}}}
  end
end
