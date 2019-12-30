defmodule ExBackend.Workflow.Definition.FrancetvSpeechToText do
  @moduledoc false

  require Logger

  def get_definition() do
    %{
      identifier: "FranceTélévisions Speech To Text",
      version_major: 0,
      version_minor: 0,
      version_micro: 1,
      tags: ["francetélévisions", "speech_to_text"],
      parameters: [],
      steps: [
        %{
          id: 0,
          name: "job_transfer",
          label: "Download source elements",
          icon: "file_download",
          enable: true,
          parameters: [
            %{
              id: "source_paths",
              type: "template",
              value: "{audio_source_filename}"
            },
            %{
              id: "source_hostname",
              type: "credential",
              value: "S3_STORAGE_HOSTNAME"
            },
            %{
              id: "source_access_key",
              type: "credential",
              value: "S3_STORAGE_ACCESS_KEY"
            },
            %{
              id: "source_secret_key",
              type: "credential",
              value: "S3_STORAGE_SECRET_KEY"
            },
            %{
              id: "source_prefix",
              type: "credential",
              value: "S3_STORAGE_BUCKET"
            },
            %{
              id: "source_region",
              type: "credential",
              value: "S3_STORAGE_REGION"
            }
          ]
        },
        %{
          id: 1,
          parent_ids: [0],
          required: [0],
          name: "job_ffmpeg",
          label: "Convert audio",
          icon: "queue_music",
          enable: true,
          parameters: [
            %{
              id: "command_template",
              type: "string",
              default:
                "ffmpeg -i {source_path} -codec:a {output_codec_audio} -ar {audio_sampling_rate} -ac {audio_channels} -af {audio_filters} -vn -dn {destination_path}",
              value:
                "ffmpeg -i {source_path} -codec:a {output_codec_audio} -ar {audio_sampling_rate} -ac {audio_channels} -af {audio_filters} -vn -dn {destination_path}"
            },
            %{
              id: "destination_filename",
              type: "template",
              enable: false,
              default: "{source_path}.wav",
              value: "{source_path}.wav"
            },
            %{
              id: "output_codec_audio",
              type: "string",
              enable: false,
              default: "pcm_s16le",
              value: "pcm_s16le"
            },
            %{
              id: "audio_sampling_rate",
              type: "integer",
              enable: false,
              default: 16_000,
              value: 16_000
            },
            %{
              id: "audio_channels",
              type: "integer",
              enable: false,
              default: 1,
              value: 1
            },
            %{
              id: "audio_filters",
              type: "string",
              enable: false,
              default: "aresample=resampler=soxr:precision=28:dither_method=shibata",
              value: "aresample=precision=28:dither_method=shibata"
            }
          ]
        },
        %{
          id: 2,
          parent_ids: [1],
          required: [1],
          name: "job_speech_to_text",
          label: "Speech To Text",
          icon: "text_fields",
          enable: true,
          parameters: [
            %{
              id: "provider",
              type: "string",
              value: "vocapia"
            },
            %{
              id: "username",
              type: "credential",
              value: "VOCAPIA_USERNAME"
            },
            %{
              id: "password",
              type: "credential",
              value: "VOCAPIA_PASSWORD"
            },
            %{
              id: "language",
              type: "template",
              value: "{language}"
            },
            %{
              id: "destination_filename",
              type: "template",
              value: "transcript.json"
            }
          ]
        },
        %{
          id: 3,
          name: "job_transfer",
          label: "Upload generated elements to S3",
          icon: "file_upload",
          enable: true,
          parent_ids: [2],
          required: [2],
          parameters: [
            %{
              id: "destination_hostname",
              type: "credential",
              default: "S3_STORAGE_HOSTNAME",
              value: "S3_STORAGE_HOSTNAME"
            },
            %{
              id: "destination_access_key",
              type: "credential",
              default: "S3_STORAGE_ACCESS_KEY",
              value: "S3_STORAGE_ACCESS_KEY"
            },
            %{
              id: "destination_secret_key",
              type: "credential",
              default: "S3_STORAGE_SECRET_KEY",
              value: "S3_STORAGE_SECRET_KEY"
            },
            %{
              id: "destination_prefix",
              type: "credential",
              default: "S3_STORAGE_BUCKET",
              value: "S3_STORAGE_BUCKET"
            },
            %{
              id: "destination_region",
              type: "credential",
              default: "S3_STORAGE_REGION",
              value: "S3_STORAGE_REGION"
            },
            %{
              id: "destination_path",
              type: "template",
              value: "{workflow_id}/transcript.json"
            }
          ]
        },
        %{
          id: 4,
          parent_ids: [3],
          name: "job_file_system",
          label: "Clean workspace",
          icon: "delete_forever",
          mode: "one_for_many",
          enable: true,
          parameters: [
            %{
              id: "action",
              type: "string",
              default: "remove",
              value: "remove"
            },
            %{
              id: "source_paths",
              type: "array_of_templates",
              value: [
                "{work_directory}/{workflow_id}"
              ]
            }
          ]
        }
      ]
    }
  end
end