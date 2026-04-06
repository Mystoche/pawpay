pipeline {
    agent any

    // Cette section télécharge et configure Node.js automatiquement
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
                    // On utilise un try/catch pour que le pipeline ne crash pas si le mail échoue
                    try {
                        mail bcc: '', body: 'Le pipeline automatique a commencé.', subject: 'Pipeline Started', to: 'dulcinemfo@gmail.com'
                    } catch (Exception e) {
                        echo "L'envoi du mail de démarrage a échoué, mais on continue le build."
                    }
                }
            }
        }

        stage('Build & Preparation') {
            steps {
                // Le code est déjà récupéré par Jenkins (Checkout SCM)
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
                        // Utilise ton conteneur Terraform trivy-scan
                        sh "docker exec trivy-scan trivy image --severity CRITICAL --exit-code 1 ${DOCKER_USER}/${IMAGE_NAME}:${IMAGE_TAG}"
                        
                        // Si 0 CRITICAL
                        mail bcc: '', 
                             body: "Le scan Trivy est terminé. Aucune vulnérabilité CRITIQUE trouvée pour l'image ${IMAGE_NAME}.", 
                             subject: "Trivy Scan: SUCCESS (0 Critical)", 
                             to: 'dulcinemfo@gmail.com'
                    } catch (Exception e) {
                        // Si CRITICAL trouvé
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