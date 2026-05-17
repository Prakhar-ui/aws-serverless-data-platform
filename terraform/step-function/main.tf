#################################################
# Fetch IAM Remote State
#################################################

data "terraform_remote_state" "iam" {
  backend = "s3"

  config = {
    bucket = "yt-terraform-state-prakhar"
    key    = "iam/terraform.tfstate"
    region = "ap-south-1"
  }
}

#################################################
# Step Function State Machine
#################################################

resource "aws_sfn_state_machine" "yt_pipeline_state_machine" {

  name = "yt-data-pipeline-orchestration-dev"

  role_arn = data.terraform_remote_state.iam.outputs.step_function_role_arn

  type = "STANDARD"

  definition = jsonencode({

    Comment = "YouTube Data Pipeline — Full orchestration via Step Functions"

    StartAt = "IngestFromYouTubeAPI"

    States = {

      #################################################
      # Ingestion Lambda
      #################################################

      IngestFromYouTubeAPI = {

        Type = "Task"

        Resource = "arn:aws:states:::lambda:invoke"

        Parameters = {
          FunctionName = "arn:aws:lambda:ap-south-1:585008079281:function:yt-data-pipeline-youtube-ingestion-dev"

          Payload = {
            triggered_by = "step_functions"

            "execution_id.$" = "$$.Execution.Id"
          }
        }

        ResultPath = "$.ingestion_result"

        Retry = [
          {
            ErrorEquals = [
              "Lambda.ServiceException",
              "Lambda.TooManyRequestsException"
            ]

            IntervalSeconds = 30

            MaxAttempts = 3

            BackoffRate = 2
          }
        ]

        Catch = [
          {
            ErrorEquals = [
              "States.ALL"
            ]

            Next = "NotifyIngestionFailure"

            ResultPath = "$.error"
          }
        ]

        Next = "WaitForS3Consistency"
      }

      #################################################
      # Wait State
      #################################################

      WaitForS3Consistency = {
        Type = "Wait"

        Seconds = 10

        Next = "ProcessInParallel"
      }

      #################################################
      # Parallel Processing
      #################################################

      ProcessInParallel = {

        Type = "Parallel"

        Branches = [

          #################################################
          # Reference Transform Branch
          #################################################

          {
            StartAt = "TransformReferenceData"

            States = {

              TransformReferenceData = {

                Type = "Task"

                Resource = "arn:aws:states:::lambda:invoke"

                Parameters = {
                  FunctionName = "arn:aws:lambda:ap-south-1:585008079281:function:yt-data-pipeline-json-to-parquet-dev"

                  Payload = {
                    triggered_by = "step_functions"
                  }
                }

                ResultPath = "$.reference_result"

                Retry = [
                  {
                    ErrorEquals = [
                      "States.ALL"
                    ]

                    IntervalSeconds = 15

                    MaxAttempts = 2

                    BackoffRate = 2
                  }
                ]

                End = true
              }
            }
          },

          #################################################
          # Bronze To Silver Glue Job Branch
          #################################################

          {
            StartAt = "RunBronzeToSilverGlueJob"

            States = {

              RunBronzeToSilverGlueJob = {

                Type = "Task"

                Resource = "arn:aws:states:::glue:startJobRun.sync"

                Parameters = {

                  JobName = "bronze_to_silver_statistics"

                  Arguments = {

                    "--bronze_database" = "yt-pipeline-bronze-dev"

                    "--bronze_table" = "raw_statistics"

                    "--silver_bucket" = "yt-data-pipeline-silver-prakhar"

                    "--silver_database" = "yt-pipeline-silver-dev"

                    "--silver_table" = "clean_statistics"

                    "--silver_path" = "youtube/clean_statistics/"
                  }
                }

                ResultPath = "$.glue_bronze_silver_result"

                Retry = [
                  {
                    ErrorEquals = [
                      "States.ALL"
                    ]

                    IntervalSeconds = 60

                    MaxAttempts = 2

                    BackoffRate = 2
                  }
                ]

                End = true
              }
            }
          }
        ]

        ResultPath = "$.parallel_results"

        Catch = [
          {
            ErrorEquals = [
              "States.ALL"
            ]

            Next = "NotifyTransformFailure"

            ResultPath = "$.error"
          }
        ]

        Next = "RunDataQualityChecks"
      }

      #################################################
      # Data Quality Lambda
      #################################################

      RunDataQualityChecks = {

        Type = "Task"

        Resource = "arn:aws:states:::lambda:invoke"

        Parameters = {
          FunctionName = "arn:aws:lambda:ap-south-1:585008079281:function:data_quality_check"

          Payload = {
            layer = "silver"

            database = "yt-pipeline-silver-dev"

            tables = [
              "clean_statistics",
              "clean_reference_data"
            ]
          }
        }

        ResultPath = "$.dq_result"

        Next = "EvaluateDataQuality"
      }

      #################################################
      # Quality Decision
      #################################################

      EvaluateDataQuality = {

        Type = "Choice"

        Choices = [
          {
            Variable = "$.dq_result.Payload.quality_passed"

            BooleanEquals = true

            Next = "RunSilverToGoldGlueJob"
          }
        ]

        Default = "NotifyDQFailure"
      }

      #################################################
      # Silver To Gold Glue Job
      #################################################

      RunSilverToGoldGlueJob = {

        Type = "Task"

        Resource = "arn:aws:states:::glue:startJobRun.sync"

        Parameters = {

          JobName = "silver_to_gold_analytics"

          Arguments = {

            "--silver_database" = "yt-pipeline-silver-dev"

            "--gold_bucket" = "yt-data-pipeline-gold-prakhar"

            "--gold_database" = "yt-pipeline-gold-dev"
          }
        }

        ResultPath = "$.glue_gold_result"

        Next = "NotifySuccess"
      }

      #################################################
      # Success Notification
      #################################################

      NotifySuccess = {

        Type = "Task"

        Resource = "arn:aws:states:::sns:publish"

        Parameters = {
          TopicArn = "arn:aws:sns:ap-south-1:585008079281:yt-data-pipeline-alerts-dev"

          Subject = "[YT Pipeline] Pipeline completed successfully"

          "Message.$" = "States.Format('Pipeline run {} completed successfully', $$.Execution.Id)"
        }

        End = true
      }

      #################################################
      # Failure Notifications
      #################################################

      NotifyIngestionFailure = {
        Type = "Fail"
      }

      NotifyTransformFailure = {
        Type = "Fail"
      }

      NotifyDQFailure = {
        Type = "Fail"
      }
    }
  })

  tags = {
    Name        = "yt-data-pipeline-orchestration-dev"
    Environment = "dev"
  }
}