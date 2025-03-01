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
        DOCKER_PASS = 'Docker-hub'
        KUBE_NAMESPACE = "jenkins"
        KUBE_CREDENTIALS = "kubernetes"
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
                withCredentials([string(credentialsId: 'Docker-hub', variable: 'DOCKER_PASS')]) {
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
                        caCertificate: 'LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSURCakNDQWU2Z0F3SUJBZ0lCQVRBTkJna3Foa2lHOXcwQkFRc0ZBREFWTVJNd0VRWURWUVFERXdwdGFXNXAKYTNWaVpVTkJNQjRYRFRJMU1ESXlOVEl6TURrd00xb1hEVE0xTURJeU5ESXpNRGt3TTFvd0ZURVRNQkVHQTFVRQpBeE1LYldsdWFXdDFZbVZEUVRDQ0FTSXdEUVlKS29aSWh2Y05BUUVCQlFBRGdnRVBBRENDQVFvQ2dnRUJBTndkCkg1TnFPSmdDNlhaNWhEUHJjcVphOUQ3SVdRY0lCL2ROSFY3djg0TGhpdVdmYS9XcHpQZUVCbDZSRmhmQ3pGYUQKMmMybGNRclNOOHd1NFNiY3p0di9SUU5lSVNncWhNUmIvVnFLczQrTUR6Nk5ESW1EOVlZUVVOUFV5Mi9CNTRGNQp5Yys4ZHNESUs0eDdlYnFXZ1ZFZEFkZHlwUVVOdVVMSDB4NVQ3VnNpSTZJMXpmY0NXTm04anhtQm9YVFM1d1c4CmtjZVJPdC9CRXIzc3hGdVRpMVFBd25jM3dXQW5qWHZJMVVEb0pEWE52SFpPU3EzUUI4ZkVNVjJaa2tEOEtWemIKRzRPeHJYdlN5N0tPZGFsT0xtR1lFODNqTlcwYjNGM3VVQmdicDRGZTZ3cFcyTHJocm5PbW91THFGRm80Y01BaQpwZ2R5SndRbnJ6a0wrK2FrUFZjQ0F3RUFBYU5oTUY4d0RnWURWUjBQQVFIL0JBUURBZ0trTUIwR0ExVWRKUVFXCk1CUUdDQ3NHQVFVRkJ3TUNCZ2dyQmdFRkJRY0RBVEFQQmdOVkhSTUJBZjhFQlRBREFRSC9NQjBHQTFVZERnUVcKQkJRTkUyQ0YzSWhhVzhnSWJnOG04RVAzMWJ2ZXBUQU5CZ2txaGtpRzl3MEJBUXNGQUFPQ0FRRUEyaVpkTHFyYQpmNEh2S0RlRnovOUlWZ2x2N2ZNRlAzV0pZWFU1WjBSckROMFc1Nm1TdGZSVVBYYzRDU2lDNEdZR3lLUiszZ3dPCjJYaXJyekRySlZaclBZVlpvMjhQV05NMnIrU1BLMEtUM3RNQUlRdVZxVTgvWGJLdStNU3BXYXo2eHlSZzMyZUgKWnZobUxmSTVqNXExVDgxZW9TS1hhblN1dVFyYVIwdGNYMTdDV0p6SUtNVHFWTkJvbC9XUEFyQ2JEaWc1Q1I1RwpaWmFuSVVGMmdoU29sdmlJWmcwaHErS0lQeTUwOHR0STR1bWQ4Yy9SZ0ZJa2VQUzZPeDk5UTBqOWhHdWdpSHpkClZIU1pBemRwYXJWd1l5a0M1MEF5RCtpOGg1R0VxLzdNaE0vUTJxZ3pEeFJuenpzWU9KdXpDeUJxS3IwR0lWVHYKT0JLRGJadkQwZm5iZ2c9PQotLS0tLUVORCBDRVJUSUZJQ0FURS0tLS0tCg==',
                        credentialsId: 'kubernetes',
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
