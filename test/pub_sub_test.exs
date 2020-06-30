defmodule PubSubTest do
  use ExUnit.Case, async: true
  doctest PubSub
  doctest PubSub.Server

  setup do
    %{
      channel: "test"
    }
  end

  test "Subscribe and receive one message", %{channel: channel} do
    subscriber = Task.async(fn ->
      assert PubSub.Server.subscribe(channel) == :ok
      publisher = Task.async(fn ->
        PubSub.Server.publish(channel, "Hello World!")
      end)
      assert Task.await(publisher) == :ok
      {_sender, ^channel, message} = PubSub.Server.poll()
      assert PubSub.Server.unsubscribe(channel) == :ok
      message
    end)
    assert Task.await(subscriber) == "Hello World!"
  end
end
