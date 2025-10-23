############################################################
# Provider Configuration
############################################################
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.3.0"
}

provider "aws" {
  region = "us-east-1" # change to your AWS region
}

############################################################
# IAM Role for Bedrock Agent
############################################################
resource "aws_iam_role" "bedrock_agent_role" {
  name = "smart-budget-buddy-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "bedrock.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "bedrock_agent_policy" {
  name = "smart-budget-buddy-policy"
  role = aws_iam_role.bedrock_agent_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = ["bedrock:InvokeModel", "logs:*", "s3:*", "cloudwatch:*"],
        Resource = "*"
      }
    ]
  })
}

############################################################
# S3 Bucket for Logs or Guardrail Files (Optional)
############################################################
resource "aws_s3_bucket" "bedrock_guardrail_bucket" {
  bucket = "smart-budget-buddy-guardrails-${random_id.bucket_id.hex}"
}

resource "random_id" "bucket_id" {
  byte_length = 4
}

############################################################
# Bedrock Guardrail Definition (Placeholder)
############################################################
resource "aws_bedrock_guardrail" "smart_budget_guardrail" {
  name        = "smart-budget-guardrail"
  description = "Ensures safe, legal, and ethical AI responses."

  content_policy_config {
    prohibited_topics = ["illegal_activities", "personal_data"]
    pii_filtering     = true
  }

  safety_config {
    enable = true
  }
}

############################################################
# Bedrock Agent Definition
############################################################
resource "aws_bedrock_agent" "smart_budget_buddy" {
  name        = "SmartBudgetBuddy"
  description = "A friendly financial literacy assistant for teens and young adults."
  foundation_model = "anthropic.claude-3-sonnet-20240229-v1:0"

  instruction = <<-EOT
You are Smart Budget Buddy, a friendly financial literacy assistant designed for teenagers and young adults who are new to managing money.

Responsibilities:
- Help users build simple weekly or monthly budgets based on their income and expenses.
- Explain money concepts in plain, beginner-friendly language (saving, needs vs. wants, debt, emergency funds).
- Provide step-by-step guidance when users ask about budgeting, spending, or saving.
- Offer encouragement and positive reinforcement.

Boundaries:
- Do not give investment, tax, or legal product recommendations.
- If users ask about those areas, politely redirect.

Tone & Style:
- Supportive, approachable, and educational.
- Use simple examples and adapt to beginners.

Greeting:
"Hello! I’m your smart financial assistant. I’m here to help you save, spend wisely, and make smart money choices. Ask me anything about managing your finances!"
EOT

  guardrail_identifier = aws_bedrock_guardrail.smart_budget_guardrail.id
  role_arn             = aws_iam_role.bedrock_agent_role.arn
}

############################################################
# CloudWatch Log Group for Monitoring (Optional)
############################################################
resource "aws_cloudwatch_log_group" "bedrock_agent_logs" {
  name              = "/aws/bedrock/smart-budget-buddy"
  retention_in_days = 14
}
