pipeline {
    agent any

    tools {
        nodejs 'node20'
    }

    triggers {
        githubPush()
    }

    environment {
        IMAGE_NAME = "pawapay"
        IMAGE_TAG = "latest"
        DOCKER_USER = "dulcinee"
        KUBE_NAMESPACE = "jenkins"
        KUBE_CRED_ID = "jenkins-k8s-SA" 
    }

    stages {
        stage('Start Pipeline') {
            steps {
                script {
                    try {
                        mail bcc: '', body: 'Le pipeline automatique a commencé.', subject: 'Pipeline Started', to: 'dulcinemfo@gmail.com'
                    } catch (Exception e) {
                        echo "L'envoi du mail de démarrage a échoué."
                    }
                }
            }
        }

        stage('Checkout GitHub') {
            steps {
                // On force le checkout ici pour régler l'erreur "not in a git directory"
                git branch: 'main', 
                    credentialsId: 'jenkis-github-mystoche', 
                    url: 'https://github.com/Mystoche/pawpay.git'
            }
        }

        stage('Install & Build TS') {
            steps {
                sh 'npm install'
                sh 'npx tsc'
            }
        }

        stage('SonarQube Analysis') {
            steps {
                script {
                    // Vérifie que le nom 'SonarQube-Scanner' est le même dans tes Tools Jenkins
                    def scannerHome = tool 'SonarQube-Scanner'
                    withSonarQubeEnv('Sonarqube') { 
                        sh "${scannerHome}/bin/sonar-scanner -Dsonar.projectName=pawapay -Dsonar.projectKey=pawapay"
                    }
                }
            }
        }

        stage("Quality Gate") {
            steps {
                script {
                    // On attend le verdict de SonarQube avant de builder l'image
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                // Utilise le socket Docker monté via Terraform
                sh "docker build -t ${DOCKER_USER}/${IMAGE_NAME}:${IMAGE_TAG} ."
            }
        }

        stage('Trivy Image Scan') {
            steps {
                script {
                    echo "--- Scan de sécurité (Image) ---"
                    try {
                        sh "docker exec trivy-scan trivy image --severity CRITICAL ${DOCKER_USER}/${IMAGE_NAME}:${IMAGE_TAG}"
                    } catch (Exception e) {
                        mail bcc: '', body: "CRITICAL trouvé par Trivy. Stop.", subject: "Trivy Scan: FAILED", to: 'dulcinemfo@gmail.com'
                        error("Le pipeline est arrêté : vulnérabilités critiques.")
                    }
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                withCredentials([string(credentialsId: 'docker', variable: 'DOCKER_PASS')]) {
                    sh "echo ${DOCKER_PASS} | docker login -u ${DOCKER_USER} --password-stdin"
                    sh "docker push ${DOCKER_USER}/${IMAGE_NAME}:${IMAGE_TAG}"
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                withKubeConfig([credentialsId: "${KUBE_CRED_ID}", serverUrl: 'https://192.168.49.2:8443']) {
                    sh "kubectl apply -f deployment.yaml -n ${KUBE_NAMESPACE}"
                }
            }
        }
    }

    post {
        success {
            mail bcc: '', body: "Pipeline SUCCESS : Déployé sur K8s.", subject: 'Pipeline Global Success', to: 'dulcinemfo@gmail.com'
        }
        failure {
            echo 'Pipeline failed. Vérifiez les logs.'
        }
    }
}
