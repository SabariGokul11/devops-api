pipeline {
    agent any

    environment {
        AWS_REGION      = 'ap-south-1'
        ECR_REGISTRY    = '137924571341.dkr.ecr.ap-south-1.amazonaws.com'
        ECR_REPOSITORY  = 'devops-api-dev'
        IMAGE_TAG       = "${BUILD_NUMBER}"
    }

    stages {

        stage('Checkout') {
            steps {
                echo 'Checking out source code...'
                checkout scm
            }
        }

        stage('Install Dependencies') {
            steps {
                sh 'npm ci --frozen-lockfile'
            }
        }

        stage('Build Docker Image') {
            steps {
                sh """
                    docker build \
                      -t ${ECR_REGISTRY}/${ECR_REPOSITORY}:${IMAGE_TAG} \
                      -t ${ECR_REGISTRY}/${ECR_REPOSITORY}:latest \
                      .
                """
            }
        }

        stage('Push to ECR') {
            steps {
                withAWS(credentials: 'aws-credentials', region: AWS_REGION) {
                    sh """
                        aws ecr get-login-password \
                          --region ${AWS_REGION} | \
                        docker login \
                          --username AWS \
                          --password-stdin \
                          ${ECR_REGISTRY}
                    """
                    sh """
                        docker push ${ECR_REGISTRY}/${ECR_REPOSITORY}:${IMAGE_TAG}
                        docker push ${ECR_REGISTRY}/${ECR_REPOSITORY}:latest
                    """
                }
            }
        }

        stage('Cleanup') {
            steps {
                sh """
                    docker rmi ${ECR_REGISTRY}/${ECR_REPOSITORY}:${IMAGE_TAG} || true
                    docker rmi ${ECR_REGISTRY}/${ECR_REPOSITORY}:latest || true
                """
            }
        }
    }

    post {
        success {
            echo '✅ Pipeline completed successfully'
        }
        failure {
            echo '❌ Pipeline failed'
        }
    }
}
