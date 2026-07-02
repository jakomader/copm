defmodule Copm.Kafka.ConsumerSupervisor do
  use Supervisor
  alias Copm.Kafka

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    children = [
      Kafka.CliConsumer,
      Kafka.UserConsumer,
      Kafka.AaaConsumer,
      Kafka.OrderConsumer,
      Kafka.TrackConsumer,
      Kafka.PaymentConsumer,
      Kafka.MsgConsumer,
      Kafka.IpdrConsumer,
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
