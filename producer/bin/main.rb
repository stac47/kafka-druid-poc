# frozen_string_literal: true

require "kafka"
require "json"
require "uuid"
require "dry-types"
require "dry-struct"

$logger = Logger.new($stderr)

CHECK_RESULTS = {
  clear: 1,
  consider: 2,
  rejected: 3
}

module Types
  include Dry.Types()
end

class CheckEvent < Dry::Struct
  attribute :timestamp, Types::Integer
  attribute :check_uuid, Types::String
  attribute :client_uuid, Types::String
  attribute :tat_ms, Types::Integer
  attribute :result, Types::Integer
end

CHECKS_TOPIC = "check-topic"

kafka = Kafka.new("localhost:9093",
                  client_id: "my-application",
                  logger: $logger)

kafka.create_topic(CHECKS_TOPIC) unless kafka.has_topic?(CHECKS_TOPIC)

producer = kafka.producer

class Client
  def initialize(uuid, producer)
    @uuid = uuid
    @producer = producer
  end

  def send_message
    event = CheckEvent.new(
      timestamp: Time.now.to_i,
      check_uuid: UUID.generate,
      client_uuid: @uuid,
      tat_ms: 1000 * Random.rand(50),
      result: CHECK_RESULTS[CHECK_RESULTS.keys.sample]
    )

    event_json = JSON.dump(event.to_h)
    $logger.info("Event to send to Kafka: #{event_json}")

    @producer.produce(event_json, topic: CHECKS_TOPIC)
  end
end

clients = (1..3).inject([]) do |memo|
  memo << Client.new(UUID.generate, producer)
end

5.times do
  client = clients.sample
  client.send_message
ensure
  producer.deliver_messages
  producer.shutdown

  $logger.info("Kafka producer closed")
end
