defmodule Pomodoro.Timer do
  use GenServer

  alias __MODULE__.State

  @timeout 100

  def start_link(remaining_milliseconds, opts) do
    GenServer.start_link(__MODULE__, {:ok, remaining_milliseconds}, opts)
  end

  def state(pid) do
    GenServer.call(pid, :state)
  end

  def start(pid) do
    GenServer.cast(pid, :start)
  end

  def pause(pid) do
    GenServer.cast(pid, :pause)
  end

  def restart(pid) do
    GenServer.cast(pid, :restart)
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
end
