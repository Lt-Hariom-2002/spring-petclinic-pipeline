pipeline {
    agent any
    
    tools {
        terraform 'ttff'
        ansible 'aann'
        maven 'mmvvnn'
    }
    environment {
        AWS_ACCESS_KEY = credentials('AWS_KEY')
        AWS_SECRET_KEY = credentials('AWS_SECRET')
        SSH_PRIVATE_KEY_PATH = "~/.ssh/hariom.pem"
    }

    stages {
        stage('Checkout Repository') {
            steps {
                git branch: 'main', url: 'https://github.com/Lt-Hariom-2002/spring-petclinic-pipeline.git'
            }
        }

        stage('Setup Terraform') {
            steps {
                script {
                    sh '''
                    terraform init
                    terraform apply -auto-approve
                    '''
                }
            }
        }

        stage('Generate Inventory') {
            steps {
                script {
                    sh """
                     echo "[artifact_server]" > inventory
                     echo "\$(terraform output -raw artifact_server_ip) ansible_user=ubuntu ansible_ssh_private_key_file=${SSH_PRIVATE_KEY_PATH} ansible_ssh_common_args='-o StrictHostKeyChecking=no'" >> inventory

                     echo "[app_server]" >> inventory
                     echo "\$(terraform output -raw app_server_ip) ansible_user=ubuntu ansible_ssh_private_key_file=${SSH_PRIVATE_KEY_PATH} ansible_ssh_common_args='-o StrictHostKeyChecking=no'" >> inventory

                     echo "[tomcat_server]" >> inventory
                     echo "\$(terraform output -raw tomcat_server_ip) ansible_user=ubuntu ansible_ssh_private_key_file=${SSH_PRIVATE_KEY_PATH} ansible_ssh_common_args='-o StrictHostKeyChecking=no'" >> inventory
                    """
                }
            }
        }

        stage('Verify Ansible Connectivity') {
            steps {
                script {
                    def servers = [
                        "artifact_server": sh(script: "terraform output -raw artifact_server_ip", returnStdout: true).trim(),
                        "app_server": sh(script: "terraform output -raw app_server_ip", returnStdout: true).trim(),
                        "tomcat_server": sh(script: "terraform output -raw tomcat_server_ip", returnStdout: true).trim()
                    ]

                    def sshUser = "ubuntu"
                    def sshPrivateKey = "${SSH_PRIVATE_KEY_PATH}"
                    def retries = 0
                    def maxRetries = 5
                    def waitTime = 10
                    def reachableServers = [:]
                    servers.each { serverName, ip -> reachableServers[serverName] = false }

                    while (reachableServers.containsValue(false) && retries < maxRetries) {
                        servers.each { serverName, ip ->
                            if (!reachableServers[serverName]) {
                                def result = sh(script: """
                                    ssh -o BatchMode=yes -o StrictHostKeyChecking=no -i ${sshPrivateKey} ${sshUser}@${ip} 'echo SSH connected'
                                """, returnStatus: true)
                                if (result == 0) {
                                    echo "${serverName} (${ip}) is reachable via SSH."
                                    reachableServers[serverName] = true
                                } else {
                                    echo "${serverName} (${ip}) not reachable yet."
                                }
                            }
                        }
                        if (reachableServers.containsValue(false)) {
                            retries++
                            echo "Attempt ${retries}/${maxRetries} failed, retrying..."
                            sleep(waitTime)
                        }
                    }
                    if (reachableServers.containsValue(false)) {
                        error "Some EC2 instances are not reachable via SSH after ${maxRetries} attempts."
                    }

                    echo "All servers reachable. Running Ansible Ping..."
                    sh "ansible -i inventory all -m ping"
                }
            }
        }

        stage('Run Ansible Setup') {
            steps {
                sh "ansible-playbook -i inventory setup.yml"
            }
        }

        stage('Build WAR File with Maven') {
            steps {
                sh "mvn clean package"
            }
        }

        stage('Copy Artifact to Servers') {
            steps {
                script {
                    sh """
                    ansible -i inventory artifact_server -m copy -a "src=target/spring-petclinic-*.jar dest=/home/ubuntu/app.jar"
                    ansible -i inventory app_server -m copy -a "src=target/spring-petclinic-*.jar dest=/home/ubuntu/app.jar"
                    """
                }
            }
        }

        stage('Run Application on App Server') {
            steps {
                script {
                    sh """
                    ansible -i inventory app_server -m shell -a "nohup java -jar /home/ubuntu/app.jar > app.log 2>&1 &"
                    """
                }
            }
        }
    }

    post {
        failure {
            echo "Build or deployment failed."
        }
        success {
            echo "Application deployed successfully."
        }
    }
}










