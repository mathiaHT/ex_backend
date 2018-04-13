defmodule ExSubtilBackend.Workflow.Step.AudioDecode do

  alias ExSubtilBackend.Jobs
  alias ExSubtilBackend.Amqp.JobFFmpegEmitter
  alias ExSubtilBackend.Workflow.Step.Requirements

  require Logger

  @action_name "audio_decode"

  def launch(workflow) do
    case get_source_files(workflow.jobs) do
      [] -> Jobs.create_skipped_job(workflow, @action_name)
      paths -> start_processing_audio(paths, workflow)
    end
  end

  defp start_processing_audio([], _workflow), do: {:ok, "started"}
  defp start_processing_audio([path | paths], workflow) do
    work_dir = System.get_env("WORK_DIR") || Application.get_env(:ex_subtil_backend, :work_dir) || "/tmp/ftp_francetv"

    filename = Path.basename(path, ".mp4")
    dst_path = work_dir <> "/" <> workflow.reference <> "/audio/"  <> filename <> ".wav"

    requirements = Requirements.add_required_paths(path)

    options = %{
      "-codec:a": "pcm_s16le",
      "-y": true,
      "-vn": true,
      "-dn": true,
      "-ar": 48000,
      "-ac": 2
    }

    job_params = %{
      name: @action_name,
      workflow_id: workflow.id,
      params: %{
        requirements: requirements,
        inputs: [
          %{
            path: path,
            options: %{}
          }
        ],
        outputs: [
          %{
            path: dst_path,
            options: options
          }
        ]
      }
    }

    {:ok, job} = Jobs.create_job(job_params)
    params = %{
      job_id: job.id,
      parameters: job.params
    }
    JobFFmpegEmitter.publish_json(params)

    start_processing_audio(paths, workflow)
  end

  defp get_source_files(jobs) do
    result =
      ExSubtilBackend.Workflow.Step.FtpDownload.get_jobs_destination_paths(jobs)
      |> Enum.filter(fn(path) -> is_audio_file?(path) end)

    ExSubtilBackend.Workflow.Step.AudioExtraction.get_jobs_destination_paths(jobs)
    |> Enum.filter(fn(path) -> is_audio_file?(path) end)
    |> Enum.concat(result)
  end

  defp is_audio_file?(path) do
    cond do
      String.ends_with?(path, "-fra.mp4") -> true
      String.ends_with?(path, "-qaa.mp4") -> true
      String.ends_with?(path, "-qad.mp4") -> true
      true -> false
    end
  end

  @doc """
  Returns the list of destination paths of this workflow step
  """
  def get_jobs_destination_paths(_jobs, result \\ [])
  def get_jobs_destination_paths([], result), do: result
  def get_jobs_destination_paths([job | jobs], result) do
    result =
      case job.name do
        @action_name ->
          job.params
          |> Map.get("destination", %{})
          |> Map.get("paths")
          |> Enum.concat(result)
        _ -> result
      end

    get_jobs_destination_paths(jobs, result)
  end

end