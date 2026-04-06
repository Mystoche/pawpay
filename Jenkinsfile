pipeline {
    agent any

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
                    mail bcc: '', body: 'Le pipeline automatique a commencé.', subject: 'Pipeline Started', to: 'dulcinemfo@gmail.com'
                }
            }
        }

        stage('Checkout & Build') {
            steps {
                git branch: 'main', url: 'https://github.com/Mystoche/pawpay.git'
                sh 'npm install'
                sh 'npx tsc'
                sh "docker build -t ${DOCKER_USER}/${IMAGE_NAME}:${IMAGE_TAG} ."
            }
        }

        stage('Trivy Image Scan') {
            steps {
                script {
                    echo "--- Scan de sécurité (Image) ---"
                    try {
                        // On lance le scan. L'exit-code 1 coupera le pipeline si CRITICAL est trouvé
                        sh "docker exec trivy-scan trivy image --severity CRITICAL --exit-code 1 ${DOCKER_USER}/${IMAGE_NAME}:${IMAGE_TAG}"
                        
                        // Si on arrive ici, c'est que le scan a trouvé 0 CRITICAL
                        mail bcc: '', 
                             body: "Le scan Trivy est terminé. Aucune vulnérabilité CRITIQUE trouvée pour l'image ${IMAGE_NAME}.", 
                             subject: "Trivy Scan: SUCCESS (0 Critical)", 
                             to: 'dulcinemfo@gmail.com'
                    } catch (Exception e) {
                        // Si le scan trouve des critiques, l'erreur est capturée ici avant de faire échouer le pipeline
                        mail bcc: '', 
                             body: "ALERTE SÉCURITÉ : Le scan Trivy a trouvé des vulnérabilités CRITIQUES sur l'image ${IMAGE_NAME}. Le déploiement est stoppé.", 
                             subject: "Trivy Scan: FAILED (Critical Found)", 
                             to: 'dulcinemfo@gmail.com'
                        error("Le pipeline est arrêté car Trivy a trouvé des vulnérabilités critiques.")
                    }
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                withCredentials([string(credentialsId: 'Docker-hub', variable: 'DOCKER_PASS')]) {
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
            mail bcc: '', body: "Le pipeline s'est terminé avec succès. L'application est déployée sur Kubernetes.", subject: 'Pipeline Global Success', to: 'dulcinemfo@gmail.com'
        }
        failure {
            echo 'Pipeline failed. Vérifiez les logs pour plus de détails.'
        }
    }
}