resource "aws_codecommit_repository" "repo" {
  repository_name = module.label.id
  tags            = module.label.tags
}

resource "aws_codebuild_project" "build" {
  name          = module.label.id
  tags          = module.label.tags
  build_timeout = 5
  service_role  = "arn:aws:iam::261219435789:role/service-role/codebuild-test-project-service-role"
  artifacts {
    type = "NO_ARTIFACTS"
  }
  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:2.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = false
  }
  source {
    type            = "CODECOMMIT"
    git_clone_depth = 1
    insecure_ssl    = false
    location        = aws_codecommit_repository.repo.clone_url_http
  }
}


resource "aws_codepipeline" "codepipelinededbbd6" {
  name     = module.label.id
  tags     = module.label.tags
  role_arn = "arn:aws:iam::261219435789:role/AWS-CodePipeline-Service"

  artifact_store {
    location = "codepipeline-eu-west-2-587756126703"
    type     = "S3"
  }

  stage {
    name = "Source"
    action {
      name = "Source"

      configuration = {
        RepositoryName       = aws_codecommit_repository.repo.repository_name
        BranchName           = "master"
        PollForSourceChanges = "false"
      }

      category = "Source"
      owner    = "AWS"
      provider = "CodeCommit"
      version  = 1

      output_artifacts = [
        "SourceArtifact"
      ]
    }
  }

  stage {
    name = "approve_release"

    action {
      category         = "Approval"
      configuration    = {}
      input_artifacts  = []
      name             = "foo"
      output_artifacts = []
      owner            = "AWS"
      provider         = "Manual"
      run_order        = 1
      version          = "1"
    }
    action {
      category         = "Approval"
      configuration    = {}
      input_artifacts  = []
      name             = "foobar"
      output_artifacts = []
      owner            = "AWS"
      provider         = "Manual"
      run_order        = 1
      version          = "1"
    }
    action {
      category         = "Approval"
      configuration    = {}
      input_artifacts  = []
      name             = "approve"
      output_artifacts = []
      owner            = "AWS"
      provider         = "Manual"
      run_order        = 2
      version          = "1"
    }
  }

  stage {
    name = "Build"
    action {
      name = "Build"

      configuration = {
        ProjectName = aws_codebuild_project.build.name
      }

      category = "Build"
      owner    = "AWS"
      provider = "CodeBuild"
      version  = 1

      input_artifacts = [
        "SourceArtifact"
      ]

      output_artifacts = [
        "BuildArtifact"
      ]
    }

    action {
      name = "Build"

      configuration = {
        ProjectName = aws_codebuild_project.build.name
      }

      category = "Build"
      owner    = "AWS"
      provider = "CodeBuild"
      version  = 1

      input_artifacts = [
        "SourceArtifact"
      ]

      output_artifacts = [
        "BuildArtifact"
      ]
    }
  }
}
