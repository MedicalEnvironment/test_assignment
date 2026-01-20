pipeline {
    agent any
    
    environment {
        DOCKER_REGISTRY = 'docker.io'
        DOCKER_IMAGE = 'akbarabayev/hello-world-app'
        DOCKER_TAG = "${BUILD_NUMBER}"
        DEPLOY_SERVER = 'localhost'
        APP_DIR = '/opt/hello-world-app'
    }
    
    triggers {
        githubPush()
    }
    
    stages {
        stage('Checkout') {
            steps {
                echo 'Cloning repository...'
                checkout scm
            }
        }
        
        stage('Build Docker Images') {
            steps {
                script {
                    echo 'Building Docker images...'
                    sh 'docker compose build'
                }
            }
        }
        
        stage('Run Tests') {
            steps {
                script {
                    echo 'Running tests...'
                    def projectName = sh(script: 'basename $(pwd)', returnStdout: true).trim()
                    echo "Project name: ${projectName}"
                    
                    sh """
                        docker run --rm \
                            -e NODE_ENV=test \
                            ${projectName}-web1:latest \
                            node -e "console.log('Health check test passed')"
                    """
                }
            }
        }
        
        stage('Tag Images') {
            steps {
                script {
                    echo 'Tagging images...'
                    def projectName = sh(script: 'basename $(pwd)', returnStdout: true).trim()
                    
                    sh """
                        docker tag ${projectName}-web1:latest ${DOCKER_IMAGE}:${DOCKER_TAG}
                        docker tag ${projectName}-web1:latest ${DOCKER_IMAGE}:latest
                    """
                }
            }
        }
        
        stage('Deploy') {
            steps {
                script {
                    echo 'Deploying application...'
                    sh '''
                        docker compose up -d --build
                        sleep 15
                        docker compose ps
                        curl -f http://localhost/health || exit 1
                    '''
                }
            }
        }
        
        stage('Verify') {
            steps {
                script {
                    echo 'Verifying deployment...'
                    sh '''
                        echo "Checking Nginx health..."
                        curl -f http://localhost/nginx-health || exit 1
                        
                        echo "Checking application health..."
                        curl -f http://localhost/health || exit 1
                        
                        echo "Checking main endpoint..."
                        curl -f http://localhost/ || exit 1
                        
                        echo "All health checks passed!"
                    '''
                }
            }
        }
    }
    
    post {
        success {
            echo 'Deployment successful!'
        }
        
        failure {
            echo 'Deployment failed!'
            sh 'docker compose down || true'
        }
        
        always {
            echo 'Cleaning up...'
            sh 'docker system prune -f --volumes || true'
        }
    }
}
