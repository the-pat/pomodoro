defmodule Pomodoro.Timer.Supervisor do
  use DynamicSupervisor

  alias Pomodoro.Timer

  @id_length 16

  def start_link(arg) do
    DynamicSupervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  def start_child(remaining_milliseconds) do
    timer_id = generate_id()

    DynamicSupervisor.start_child(
      __MODULE__,
      {Timer, timer_id: timer_id, remaining_milliseconds: remaining_milliseconds}
    )

    timer_id
  end

  @impl true
  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  defp generate_id() do
    @id_length
    |> :crypto.strong_rand_bytes()
    |> Base.url_encode64(padding: false)
  end
end
