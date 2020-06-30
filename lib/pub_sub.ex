defmodule PubSub do
  @moduledoc """
  Example about PubSub.
  """
  use Application

  @impl true
  def start(_type, _args) do
    # Although we don't use the supervisor name below directly,
    # it can be useful when debugging or introspecting the system.
    children = [
      {PubSub.Server, name: PubSub.Server},
    ]

    Supervisor.start_link(children, strategy: :one_for_all)
  end
end
