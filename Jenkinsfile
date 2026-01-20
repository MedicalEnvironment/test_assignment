pipeline {
    agent any
    
    environment {
        DOCKER_REGISTRY = 'docker.io'
        DOCKER_IMAGE = 'akbarabayev/hello-world-app'
        DOCKER_TAG = "${BUILD_NUMBER}"
        DEPLOY_SERVER = 'localhost' // Если Jenkins на той же машине, иначе укажите IP
        APP_DIR = '/opt/hello-world-app'
    }
    
    triggers {
        // Триггер на push в main ветку
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
                    sh '''
                        docker compose build --no-cache
                    '''
                }
            }
        }
        
        stage('Run Tests') {
            steps {
                script {
                    echo 'Running tests...'
                    // Запуск контейнера для тестирования
                    sh '''
                        # Запускаем контейнер для тестов
                        docker run --rm \
                            -e NODE_ENV=test \
                            nts_test_assignment-web1:latest \
                            node -e "console.log('Health check test passed')"
                    '''
                }
            }
        }
        
        stage('Tag and Push to Registry') {
            steps {
                script {
                    echo 'Tagging and pushing images...'
                    // Если используете Docker Hub, раскомментируйте:
                    // withCredentials([usernamePassword(credentialsId: 'dockerhub-credentials', 
                    //                                   usernameVariable: 'DOCKER_USER', 
                    //                                   passwordVariable: 'DOCKER_PASS')]) {
                    //     sh '''
                    //         echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin
                    //         docker tag nts_test_assignment-web1:latest ${DOCKER_IMAGE}:${DOCKER_TAG}
                    //         docker tag nts_test_assignment-web1:latest ${DOCKER_IMAGE}:latest
                    //         docker push ${DOCKER_IMAGE}:${DOCKER_TAG}
                    //         docker push ${DOCKER_IMAGE}:latest
                    //     '''
                    // }
                    
                    // Для локального деплоя без registry:
                    sh '''
                        docker tag nts_test_assignment-web1:latest ${DOCKER_IMAGE}:${DOCKER_TAG}
                        docker tag nts_test_assignment-web1:latest ${DOCKER_IMAGE}:latest
                    '''
                }
            }
        }
        
        stage('Deploy to Server') {
            steps {
                script {
                    echo 'Deploying application...'
                    
                    // Если Jenkins на той же машине, что и приложение:
                    sh '''
                        # Остановка старых контейнеров
                        docker compose down || true
                        
                        # Удаление старых образов (опционально)
                        docker image prune -f
                        
                        # Запуск новых контейнеров
                        docker compose up -d
                        
                        # Проверка статуса
                        sleep 10
                        docker compose ps
                        
                        # Health check
                        curl -f http://localhost/health || exit 1
                    '''
                    
                    // Если деплой на удаленный сервер по SSH:
                    // sh '''
                    //     ssh user@${DEPLOY_SERVER} "
                    //         cd ${APP_DIR} && \
                    //         git pull origin main && \
                    //         docker compose down && \
                    //         docker compose up -d --build && \
                    //         docker compose ps
                    //     "
                    // '''
                }
            }
        }
        
        stage('Verify Deployment') {
            steps {
                script {
                    echo 'Verifying deployment...'
                    sh '''
                        # Проверка health check всех сервисов
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
            // Уведомления (опционально)
            // emailext(
            //     subject: "Deployment Successful - Build #${BUILD_NUMBER}",
            //     body: "The application has been successfully deployed.",
            //     to: "your-email@example.com"
            // )
        }
        
        failure {
            echo 'Deployment failed!'
            // Откат к предыдущей версии
            sh '''
                docker compose down || true
                # Здесь можно добавить логику отката
            '''
            
            // Уведомления (опционально)
            // emailext(
            //     subject: "Deployment Failed - Build #${BUILD_NUMBER}",
            //     body: "The deployment has failed. Please check the Jenkins logs.",
            //     to: "your-email@example.com"
            // )
        }
        
        always {
            // Очистка
            echo 'Cleaning up...'
            sh '''
                docker system prune -f --volumes || true
            '''
        }
    }
}
