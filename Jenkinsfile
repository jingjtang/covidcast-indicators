/* import shared library */
@Library('jenkins-shared-library') _

pipeline {
    agent any

    environment {
        INDICATOR = "${env.BRANCH_NAME}"
    }

    stages {
        stage('Build') {
            when {
                branch "deploy-*"
            }
            steps {
                sh "jenkins/$(${INDICATOR} | tr -d "deploy-")-jenkins-build.sh"
            }
        }

        stage('Test') {
            when {
                branch "deploy-*"
            }
            steps {
                sh "jenkins/$(${INDICATOR} | tr -d "deploy-")-jenkins-test.sh"
            }
        }
        
        stage('Package') {
            when {
                branch "deploy-*"
            }
            steps {
                sh "jenkins/$(${INDICATOR} | tr -d "deploy-")-jenkins-package.sh"
            }
        }

        stage('Deploy') {
            when {
                branch "deploy-*"
            }
            steps {
                sh "jenkins/$(${INDICATOR} | tr -d "deploy-")-jenkins-deploy.sh"
            }
        }
    }

    post {
        always {
            script {
                /* Use slackNotifier.groovy from shared library and provide current build result as parameter */   
                slackNotifier(currentBuild.currentResult)
                //cleanWs()
            }
        }
    }
}
