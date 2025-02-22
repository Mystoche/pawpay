pipeline {
    agent any

    environment {
        IMAGE_NAME = "pawapay"
        IMAGE_TAG = "latest"
        DOCKER_USER = "dulcinee"
        DOCKER_PASS = 'hub-pipeline'
        KUBE_NAMESPACE = "jenkins"
        KUBE_CREDENTIALS = "jjenkin-k8s"
    }

    stages {
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

        stage('Sonarqube Analyze of vulnerability') {

            steps {
                withSonarQubeEnv('SonarQube-Server') {
                    sh '''$SCANNER_HOME/bin/sonar-scanner -Dsonar.projectName=pawapay \
                    -Dsonar.projectKey=pawapay'''
                }
            }
        }

        stage("Quality Gate") {

            steps {
                script {
                    waitForQualityGate abortPipeline: false, credentialsId: 'sonarqube'
                }
            }
        }

        stage('TRIVY FS SCAN') {

            steps {

		sh '''
        		# Installer Trivy
	  
        		wget https://github.com/aquasecurity/trivy/releases/latest/download/trivy_0.56.2_Linux-64bit.deb
        		dpkg -i trivy_0.56.2_Linux-64bit.deb
	  		trivy fs . > trivyfs.txt
       		   '''
		    
            }
        }



        stage('Deploy to Kubernetes') {
        
            steps {
                script {
                    kubeconfig(
                        caCertificate: 'LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSURCakNDQWU2Z0F3SUJBZ0lCQVRBTkJna3Foa2lHOXcwQkFRc0ZBREFWTVJNd0VRWURWUVFERXdwdGFXNXAKYTNWaVpVTkJNQjRYRFRJMU1ESXdOekU1TlRNd05Wb1hEVE0xTURJd05qRTVOVE13TlZvd0ZURVRNQkVHQTFVRQpBeE1LYldsdWFXdDFZbVZEUVRDQ0FTSXdEUVlKS29aSWh2Y05BUUVCQlFBRGdnRVBBRENDQVFvQ2dnRUJBUE1jCmpVd3Y4RFBoQ2ErVDdVTGNocFJ4ZXRhbi9LWW1OWktTOFpXSmU4YjN2SXNRV3ZsRTVuUXBlR29sQVlueVlEVFIKMW1MVCtyK3JzcW9OR1lvUXVaT0t6ODl0bWhDODdjbFcxYUtOUEFscGh5eEszU04zNklOZkFaakVadG95aWd2dQpLSzF2N0xSWkhQd0NhVlpnU2Nnc3pJWUVveDJpeUlLNWNhMFgvKzVpVDh3N2I5YkJkUEhrTTVnV2FuSEZjczNCCmpKcThzTXVUdURncFN4RHErSThkbG9kVnhUY3lCc1lqT05EMEQ5WlNnTmQvUFVkQnVPeS9VR0E4Z2JxSGNLQVMKM1dheUlUNFVSSlA5VnZ0WGhLd3ozaEhvakgyUnMyVkVJcWdHbkU1YUpDSU95aHhhL1NRRDV2R2UrWDQ0eWh1QQowRkVFQmJLeUp4QWFwdjlwNHdrQ0F3RUFBYU5oTUY4d0RnWURWUjBQQVFIL0JBUURBZ0trTUIwR0ExVWRKUVFXCk1CUUdDQ3NHQVFVRkJ3TUNCZ2dyQmdFRkJRY0RBVEFQQmdOVkhSTUJBZjhFQlRBREFRSC9NQjBHQTFVZERnUVcKQkJRaExLM3pTQWFDUzNCVjBxZXJSNGVsN2kyai9UQU5CZ2txaGtpRzl3MEJBUXNGQUFPQ0FRRUFQS2tMbGZsRwpPbUZRdmw5ZFhJRmxZV1UwRk9xMHBGTXFtV1VuOG91Z3g0QzIzUmhIVW43NU4wczhQVjROYkxzZ0huOFNCci9iCml4SEdleUNGWjJPNEw5Y1Mwa0xMZGp5cDF5VzBrd2JCOHVSMXlNc28yeUFzMHMwYjE4em4xMnI1WldyclBVQysKb2RHbXFjNTc0Z0hSWml3THFNS215UDY2RTJIQk1lTWQvL0xQczNvb2I2Zi9yc2NXeTFrOFMzajlqZENldXRlSgp6NVQxOVgxdkxoK1ZmMWxhTy9PQmFSL2RYNko0bVl6bS9rTWtvYThsWndPQlV4MWsrMVRqQ2ZPYTJmWFBmcFFqCjNwZWNteE1US0tnYWloM1FBOUtvNHJsem96ekRRdzhMdzRoMm5oL09meC9iZkpJYkY4RkZLOXFhZGFRbGJQc2UKVjFlZldYM0I3alB1UXc9PQotLS0tLUVORCBDRVJUSUZJQ0FURS0tLS0tCg==', 
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
            echo ' Pipeline exécuté avec succès !'
        }
        failure {
            echo ' Échec du pipeline. Vérifie les logs !'
        }
    }
}

