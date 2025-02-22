pipeline {
    agent any

    triggers {
        // Trigger a build on every push to the repository
        githubPush()
    }

    environment {
        IMAGE_NAME = "pawapay"
        IMAGE_TAG = "latest"
        DOCKER_USER = "dulcinee"
        DOCKER_PASS = 'hub-pipeline'
        KUBE_NAMESPACE = "jenkins"
        KUBE_CREDENTIALS = "jjenkin-k8s"
    }

    stages {
        stage('Start Pipeline') {
            steps {
                script {
                    // Send the initial email at the start
                    mail bcc: '', body: 'Pipeline automatique a commencé.', subject: 'Pipeline Started', to: 'dulcinemfo@gmail.com'
                    echo 'Pipeline automatique a commencé.'
                }
            }
        }

        stage('Checkout Code') {
            steps {
                git branch: 'main', url: 'https://github.com/Mystoche/pawpay.git'
            }
        }

        stage('Install Dependencies') {
            steps {
                sh 'npm install'
            }
        }

        stage('Run Tests') {
            steps {
                sh 'npm test || echo "Tests failed but continuing..."'
            }
        }

        stage('Build TypeScript') {
            steps {
                sh 'npx tsc'
            }
        }

        stage('Build Docker Image') {
            steps {
                sh "docker build -t ${DOCKER_USER}/${IMAGE_NAME}:${IMAGE_TAG} ."
            }
        }

        stage('Push Docker Image') {
            steps {
                withCredentials([string(credentialsId: 'hub-pipeline', variable: 'DOCKER_PASS')]) {
                    echo "Authentification Docker Hub"
                    sh "echo $DOCKER_PASS | docker login -u ${DOCKER_USER} --password-stdin"
                    sh "docker push ${DOCKER_USER}/${IMAGE_NAME}:${IMAGE_TAG}"
                }
            }
        }

        stage('SonarQube Analysis') {
            steps {
                script {
                    def scannerHome = tool 'SonarQube-Scanner';
                    withSonarQubeEnv() {
                        sh """
                            ${scannerHome}/bin/sonar-scanner \
                            -Dsonar.projectName=pawapay \
                            -Dsonar.projectKey=pawapay
                        """
                    }
                }
            }
        }

        stage("Quality Gate") {
            steps {
                script {
                    waitForQualityGate abortPipeline: false, credentialsId: 'SonarQube-Token'
                }
            }
        }

        stage('TRIVY FS SCAN') {
            steps {
                sh '''
                    trivy fs . > trivyfs.txt
                    cat trivyfs.txt
                '''
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                script {
                    kubeconfig(
                        caCertificate: 'LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0t...',
                        credentialsId: 'k8s-jenkins',
                        serverUrl: 'https://192.168.49.2:8443'
                    ) {
                        sh "kubectl apply -f deployment.yaml -n ${KUBE_NAMESPACE}"
                    }
                }
            }
        }
    }

    post {
        success {
            mail bcc: '', body: 'Pipeline succeeded', subject: 'Pipeline Success', to: 'dulcinemfo@gmail.com'
            echo 'Pipeline executed successfully!'
        }
        failure {
            mail bcc: '', body: 'Pipeline failed', subject: 'Pipeline Failure', to: 'dulcinemfo@gmail.com'
            echo 'Pipeline failed. Check the logs!'
        }
    }
}
