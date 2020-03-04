defmodule Pomodoro.Timer.State do
  alias __MODULE__

  defstruct [:state, :remaining_milliseconds, :last_updated, :starting_milliseconds]

  def new(state, remaining_milliseconds) do
    %State{
      state: state,
      remaining_milliseconds: remaining_milliseconds,
      last_updated: DateTime.utc_now(),
      starting_milliseconds: remaining_milliseconds
    }
  end
end
