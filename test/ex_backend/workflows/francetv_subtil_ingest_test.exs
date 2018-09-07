defmodule ExBackend.FrancetvSubtilIngestTest do
  use ExBackendWeb.ConnCase

  alias ExBackend.Workflows
  alias ExBackend.WorkflowStep

  require Logger

  describe "francetv_subtil_ingest_workflow" do
    test "bad id" do
      acs_enable = false

      steps = ExBackend.Workflow.Definition.FrancetvSubtilIngest.get_definition(acs_enable)

      workflow_params = %{
        reference: "bad_movie_id",
        flow: steps
      }

      {:ok, workflow} = Workflows.create_workflow(workflow_params)
      {:ok, "started"} = WorkflowStep.start_next_step(workflow)
      ExBackend.HelpersTest.check(workflow.id, 3)
      ExBackend.HelpersTest.check(workflow.id, "download_ftp", 1)
      ExBackend.HelpersTest.check(workflow.id, "download_http", 1)

      {:error, "unable to publish RDF"} = WorkflowStep.start_next_step(workflow)
    end

    test "il etait une fois la vie" do
      acs_enable = false

      steps = ExBackend.Workflow.Definition.FrancetvSubtilIngest.get_definition(acs_enable)

      workflow_params = %{
        reference: "99787afd-ba2d-410f-b03e-66cf2efb3ed5",
        flow: steps
      }

      {:ok, workflow} = Workflows.create_workflow(workflow_params)

      {:ok, "started"} = WorkflowStep.start_next_step(workflow)
      ExBackend.HelpersTest.check(workflow.id, 5)
      ExBackend.HelpersTest.check(workflow.id, "download_ftp", 5)
      ExBackend.HelpersTest.complete_jobs(workflow.id, "download_ftp")

      {:ok, "started"} = WorkflowStep.start_next_step(workflow)
      ExBackend.HelpersTest.check(workflow.id, 6)
      ExBackend.HelpersTest.check(workflow.id, "download_http", 1)
      ExBackend.HelpersTest.complete_jobs(workflow.id, "download_http")

      {:ok, "started"} = WorkflowStep.start_next_step(workflow)
      ExBackend.HelpersTest.check(workflow.id, 7)
      ExBackend.HelpersTest.check(workflow.id, "audio_extraction", 1)
      ExBackend.HelpersTest.complete_jobs(workflow.id, "audio_extraction")

      {:ok, "started"} = WorkflowStep.start_next_step(workflow)
      ExBackend.HelpersTest.check(workflow.id, 11)
      ExBackend.HelpersTest.check(workflow.id, "ttml_to_mp4", 1)
      ExBackend.HelpersTest.complete_jobs(workflow.id, "ttml_to_mp4")
      ExBackend.HelpersTest.set_gpac_outputs(workflow.id, "ttml_to_mp4", "subtitle.mp4")

      {:ok, "started"} = WorkflowStep.start_next_step(workflow)
      ExBackend.HelpersTest.check(workflow.id, 12)
      ExBackend.HelpersTest.check(workflow.id, "set_language", 1)
      ExBackend.HelpersTest.complete_jobs(workflow.id, "set_language")
      ExBackend.HelpersTest.set_gpac_outputs(workflow.id, "set_language", "subtitle-fra.mp4")

      {:ok, "started"} = WorkflowStep.start_next_step(workflow)
      ExBackend.HelpersTest.check(workflow.id, 13)
      ExBackend.HelpersTest.check(workflow.id, "generate_dash", 1)
      ExBackend.HelpersTest.complete_jobs(workflow.id, "generate_dash")

      ExBackend.HelpersTest.set_gpac_outputs(workflow.id, "generate_dash", [
        "/tmp/manifest.mpd",
        "/tmp/video_track.mp4",
        "/tmp/audio_track.mp4"
      ])

      {:ok, "started"} = WorkflowStep.start_next_step(workflow)
      ExBackend.HelpersTest.check(workflow.id, 16)
      ExBackend.HelpersTest.check(workflow.id, "upload_ftp", 3)
      ExBackend.HelpersTest.complete_jobs(workflow.id, "upload_ftp")

      {:error, "unable to publish RDF"} = WorkflowStep.start_next_step(workflow)
    end

    test "il etait une fois la vie with ACS" do
      acs_enable = true

      steps = ExBackend.Workflow.Definition.FrancetvSubtilIngest.get_definition(acs_enable)

      workflow_params = %{
        reference: "99787afd-ba2d-410f-b03e-66cf2efb3ed5",
        flow: steps
      }

      {:ok, workflow} = Workflows.create_workflow(workflow_params)

      {:ok, "started"} = WorkflowStep.start_next_step(workflow)
      ExBackend.HelpersTest.check(workflow.id, 5)
      ExBackend.HelpersTest.check(workflow.id, "download_ftp", 5)
      ExBackend.HelpersTest.complete_jobs(workflow.id, "download_ftp")

      {:ok, "started"} = WorkflowStep.start_next_step(workflow)
      ExBackend.HelpersTest.check(workflow.id, 6)
      ExBackend.HelpersTest.check(workflow.id, "download_http", 1)
      ExBackend.HelpersTest.complete_jobs(workflow.id, "download_http")

      {:ok, "started"} = WorkflowStep.start_next_step(workflow)
      ExBackend.HelpersTest.check(workflow.id, 7)
      ExBackend.HelpersTest.check(workflow.id, "audio_extraction", 1)
      ExBackend.HelpersTest.complete_jobs(workflow.id, "audio_extraction")

      {:ok, "started"} = WorkflowStep.start_next_step(workflow)
      ExBackend.HelpersTest.check(workflow.id, 11)
      ExBackend.HelpersTest.check(workflow.id, "ttml_to_mp4", 1)
      ExBackend.HelpersTest.complete_jobs(workflow.id, "ttml_to_mp4")

      {:ok, "started"} = WorkflowStep.start_next_step(workflow)
      ExBackend.HelpersTest.check(workflow.id, 13)
      ExBackend.HelpersTest.check(workflow.id, "set_language", 1)
      ExBackend.HelpersTest.complete_jobs(workflow.id, "set_language")
      ExBackend.HelpersTest.check(workflow.id, "generate_dash", 1)
      ExBackend.HelpersTest.complete_jobs(workflow.id, "generate_dash")
      ExBackend.HelpersTest.check(workflow.id, "upload_ftp", 0)
      ExBackend.HelpersTest.complete_jobs(workflow.id, "upload_ftp")

      {:error, "unable to publish RDF"} = WorkflowStep.start_next_step(workflow)
    end
  end
end