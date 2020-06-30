defmodule PubSub.Server do
  @moduledoc """
  PubSub server.
  """
  use GenServer


  def start_link(_options) do
    GenServer.start_link(__MODULE__, [], name: PubSub.Server)
  end


  # Client

  @doc """
  Subscribe to a channel, waiting until PubSub subscribe process caller to the channel.
  """
  def subscribe(channel) do
    GenServer.call(PubSub.Server, {:subscribe, channel})
  end

  @doc """
  Unsubscribe from a channel, waiting until PubSub subscribe process caller from the channel.
  """
  def unsubscribe(channel) do
    GenServer.call(PubSub.Server, {:unsubscribe, channel})
  end

  @doc """
  Check messages from subscriptions.

  Returns `{sender, channel, message}` if there is a message, `:ok` otherwise.
  This will discard other messages.
  """
  def poll(timeout \\ 0) do
    receive do
      {PubSub.Server, sender, channel, message} -> {sender, channel, message}
      # See: https://www.erlang-solutions.com/blog/receiving-messages-in-elixir-or-a-few-things-you-need-to-know-in-order-to-avoid-performance-issues.html
      _ -> :ok
      after timeout -> :ok
    end
  end

  @doc """
  Publish a message asynchronously.
  """
  def publish(channel, message) do
    GenServer.cast(PubSub.Server, {:publish, self(), channel, message})
  end


  # Server

  @impl true
  def init([]) do
    {:ok, :ets.new(:pubsub_subscriptions, [:bag, :private])}
  end

  @impl true
  def handle_call(request, {pid, _tag} = _from, state) do
    case request do
      {:subscribe, channel} ->
        reply = if :ets.insert_new(state, {channel, pid}) do
          :ok
        else
          :err
        end
        {:reply, reply, state}
      {:unsubscribe, channel} ->
        :ets.delete_object(state, {channel, pid})
        {:reply, :ok, state}
    end
  end

  @impl true
  def handle_cast(request, state) do
    case request do
      {:publish, sender, channel, message} ->
        for {^channel, subscriber} <- :ets.lookup(state, channel) do
          send(subscriber, {PubSub.Server, sender, channel, message})
        end
    end
    {:noreply, state}
  end
end
