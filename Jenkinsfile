pipeline {
    agent any
    parameters {
        string(name: 'VERSION', defaultValue: '1.2', description: 'release version')
    }
    environment {
        AWS_ACCOUNT_ID = '324037305534'
        AWS_REGION = 'ap-south-1'
        IMAGE_NAME = 'cowsay-naor'
        REPO_NAME = 'cowsay-naor'
        ECR_URI = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${REPO_NAME}"
        EC2_INSTANCE_IP = '65.2.81.193'
        REMOTE_HOST = "${EC2_INSTANCE_IP}"
        ECR_REPO = "${ECR_URI}"
        DEV_EMAIL = 'Naorlad98@gmail.com'
        VERSION_FILE = 'v.txt'
        BRANCH = "release/${params.VERSION}"
    }

    stages {
        stage('Checkout Code') {
            steps {
                script {
                    echo "Checking out the latest code"
                    withCredentials([sshUserPrivateKey(credentialsId: 'gitRssh', keyFileVariable: 'SSH_KEY_PATH', usernameVariable: 'SSH_USER')]) {
                        sh """
                            export GIT_SSH_COMMAND="ssh -i \$SSH_KEY_PATH -o StrictHostKeyChecking=no"
                            git fetch --all
                            if git rev-parse --verify origin/${BRANCH}; then
                                git checkout ${BRANCH}
                                git pull origin ${BRANCH}
                                echo "In branch ${BRANCH}"
                            else
                                echo "BRANCH DOES NOT EXIST"
                                exit 1
                            fi
                        """
                    }
                }
            }
        }

        stage('Determine Version') {
            steps {
                script {
                    def lastVersion =  sh(script: "cat ${VERSION_FILE}", returnStdout: true).trim()
                    def versionParts = lastVersion.tokenize('.')
                    def major = versionParts[0]
                    def minor = versionParts[1]
                    def patch = versionParts.size() > 2 ? versionParts[2].toInteger() + 1 : 0
                    env.BUILD_VERSION = "${major}.${minor}.${patch}"

                    sh "echo '${env.BUILD_VERSION}' > '${VERSION_FILE}'"
                    echo "New build version set to: ${env.BUILD_VERSION}"
                }
            }
        }


        stage('Build Docker Image') {
            steps {
                script {
                    dir('repo') {
                        echo "Building the Docker image"
                        sh """
                            aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_URI}
                            docker build -t ${IMAGE_NAME}:${env.BUILD_VERSION} .
                        """
                    }
                }
            }
        }

        stage('E2E TESTS') {
            steps {
                script {
                    sh """
                        echo "Stopping test containers"
                        sudo docker stop cowsay-test || true
                        sudo docker rm cowsay-test || true
                        sudo docker run -d --name cowsay-test -p 8081:8080 ${IMAGE_NAME}:${env.BUILD_VERSION}"
                        sleep 15
                        docker ps | grep cowsay-test || (echo "failed to run" && exit 1)
                        sudo docker stop cowsay-test
                        sudo docker rm cowsay-test
                    """
                }
            }
        }

        stage('Deploy to EC2') {
            steps {
                script {
                    echo "Deploying to EC2 instance"
                    withCredentials([sshUserPrivateKey(credentialsId: 'raskey', keyFileVariable: 'SSH_KEY_PATH', usernameVariable: 'SSH_USER')]) {
                        sh """
                            echo "Checking SSH Key Path: \$SSH_KEY_PATH"
                            chmod 600 \$SSH_KEY_PATH
                            docker tag ${IMAGE_NAME}:${env.BUILD_VERSION} ${ECR_URI}:${env.BUILD_VERSION}
                            docker push ${ECR_URI}:${env.BUILD_VERSION}
                            ssh -i \$SSH_KEY_PATH -o StrictHostKeyChecking=no \$SSH_USER@${REMOTE_HOST} "set -e && \
                            echo 'Logging into AWS ECR...' && \
                            aws ecr get-login-password --region ${AWS_REGION} | sudo docker login --username AWS --password-stdin ${ECR_REPO} && \
                            echo 'Pulling latest Docker image...' && \
                            sudo docker pull ${ECR_REPO}:${env.BUILD_VERSION} && \
                            echo 'Stopping existing container if it exists...' && \
                            sudo docker stop cowsay-container || true && \
                            sudo docker rm cowsay-container || true && \
                            echo 'Running new container...' && \
                            sudo docker run -d --name cowsay-container -p 8081:8080 ${ECR_REPO}:${env.BUILD_VERSION}"
                        """
                    }
                }
            }
        }

        stage('Sanity Check') {
            steps {
                script {
                    echo "Performing Sanity Check"
                    sleep 15
                    def testResult = sh(script: "curl -v http://${EC2_INSTANCE_IP}:8081", returnStatus: true)
                    if (testResult == 0) {
                        echo "Test successful. Application is responding."
                    } else {
                        echo "Test failed. Application is not responding."
                        error "Application did not respond successfully."
                    }
                }
            }
        }

        stage('Cleanup and Tag Release') {
            steps {
                script {
                    withCredentials([sshUserPrivateKey(credentialsId: 'gitRssh', keyFileVariable: 'SSH_KEY_PATH', usernameVariable: 'SSH_USER')]) {
                        sh """
                            echo "Resetting file changes and tagging release"
                            export GIT_SSH="ssh -i \$SSH_KEY_PATH -o StrictHostKeyChecking=no"
                            git restore ${VERSION_FILE}
                            git tag ${env.BUILD_VERSION}
                            git push origin ${env.BUILD_VERSION}
                        """
                    }
                }
            }
        }
    }

    post {
        always {
            echo "Cleaning up unnecessary containers"
            sh "docker rm -f cowsay-container || true"
        }
        success {
            echo "Deployment completed successfully."
            script {
                def buildStatus = currentBuild.result ?: 'SUCCESS'
                def subject = "Jenkins Build ${buildStatus}: cowsayPipeline"
                def body = """
                Jenkins Build Notification
                Job Name: ${env.JOB_NAME}
                Build Number: ${env.BUILD_NUMBER}
                Status: ${buildStatus}
                Build URL: ${env.BUILD_URL}
                """
                mail to: "${DEV_EMAIL}",
                subject: subject,
                body: body
            }
            sh """
                curl -X POST -H "Content-Type: application/json" -d '{
                    "text": "Deployment Success. The latest version of Cowsay-Naor (${env.BUILD_VERSION}) has been successfully deployed to EC2."
                }' http://65.0.27.147:8080/project/cow_pipeline
            """
        }
        failure {
            echo "Deployment failed."
            script {
                mail to: "${DEV_EMAIL}",
                subject: "Jenkins Build FAILED: cowsayPipeline",
                body: "The Jenkins build for cowsayPipeline has FAILED.\nBuild URL: ${env.BUILD_URL}"
            }
            sh """
                curl -X POST -H "Content-Type: application/json" -d '{
                    "text": "Deployment Failed. The deployment of Cowsay-Naor (${env.BUILD_VERSION}) has failed. Check Jenkins logs for details."
                }' http://65.0.27.147:8080/project/cow_pipeline
            """
        }
    }
}
