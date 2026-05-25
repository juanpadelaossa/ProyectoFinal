resource "aws_sfn_state_machine" "etl_pipeline" {
  name     = "Proyecto_Final"
  role_arn = var.sfn_role_arn

  definition = jsonencode({
    Comment = "Pipeline con Quality Gate previo (Great Expectations)"
    StartAt = "quality_check"
    States = {
      quality_check = {
        Type     = "Task"
        Resource = "arn:aws:states:::glue:startJobRun.sync"
        Parameters = {
          JobName = "Proyecto_great_expectation"
        }
        Next = "bronze_to_silver"
        Catch = [
          {
            ErrorEquals = ["States.ALL"]
            ResultPath  = "$.error"
            Next        = "quality_failed"
          }
        ]
      }
      bronze_to_silver = {
        Type     = "Task"
        Resource = "arn:aws:states:::glue:startJobRun.sync"
        Parameters = {
          JobName = "Proyecto_bronze_to_silver"
        }
        Next = "silver_to_gold"
        Catch = [
          {
            ErrorEquals = ["States.ALL"]
            ResultPath  = "$.error"
            Next        = "pipeline_failed"
          }
        ]
      }
      silver_to_gold = {
        Type     = "Task"
        Resource = "arn:aws:states:::glue:startJobRun.sync"
        Parameters = {
          JobName = "Proyecto_silver_to_gold"
        }
        End = true
        Catch = [
          {
            ErrorEquals = ["States.ALL"]
            ResultPath  = "$.error"
            Next        = "pipeline_failed"
          }
        ]
      }
      quality_failed = {
        Type  = "Fail"
        Error = "DataQualityFailed"
        Cause = "El job Proyecto_great_expectation falló. El pipeline se detuvo."
      }
      pipeline_failed = {
        Type  = "Fail"
        Error = "PipelineFailed"
        Cause = "Un job del pipeline falló. Revisa los logs en CloudWatch."
      }
    }
  })

  tags = var.tags
}