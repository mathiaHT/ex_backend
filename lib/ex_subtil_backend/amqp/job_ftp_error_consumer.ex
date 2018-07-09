defmodule ExSubtilBackend.Amqp.JobFtpErrorConsumer do
  require Logger

  alias ExSubtilBackend.Jobs.Status
  alias ExSubtilBackend.Workflows

  use ExSubtilBackend.Amqp.CommonConsumer, %{
    queue: "job_ftp_error",
    consumer: &ExSubtilBackend.Amqp.JobFtpErrorConsumer.consume/4
  }

  def consume(channel, tag, _redelivered, %{"job_id" => job_id, "error" => description} = payload) do
    Logger.error("FTP error #{inspect(payload)}")
    Status.set_job_status(job_id, "error", %{message: description})
    Workflows.notification_from_job(job_id)
    Basic.ack(channel, tag)
  end

  def consume(channel, tag, _redelivered, %{"error" => description} = payload) do
    Logger.error("FTP error #{inspect(payload)}")
    Basic.ack(channel, tag)
  end
end
