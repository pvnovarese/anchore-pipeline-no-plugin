// requires anchore-cli https://github.com/anchore/anchore-cli
// requires anchore engine or anchore enterprise 
//
pipeline {
  environment {
    // set some variables
    //
    // we don't need registry if using docker hub
    // but if you're using a different registry, set this 
    // REGISTRY = 'registry.hub.docker.com'
    //
    // set path for syft executable.  I put this in jenkins_home as noted
    // in README but you may install it somewhere else like /usr/local/bin
    SYFT_LOCATION = "/var/jenkins_home/syft"
    //
    // you will need a credential with your docker hub user/pass
    // (or whatever registry you're using) and a credential with
    // user/pass for your anchore instance:
    // ...
    // first let's set the docker hub credential and extract user/pass
    // we'll use the USR part for figuring out where are repository is
    HUB_CREDENTIAL = "docker-hub"
    // use credentials to set DOCKER_HUB_USR and DOCKER_HUB_PSW
    DOCKER_HUB = credentials("${HUB_CREDENTIAL}")
    // we'll need the anchore credential to pass the user
    // and password to syft so it can upload the results
    ANCHORE_CREDENTIAL = "AnchoreJenkinsUser"
    // use credentials to set ANCHORE_USR and ANCHORE_PSW
    ANCHORE = credentials("${ANCHORE_CREDENTIAL}")
    //
    // api endpoint of your anchore instance
    ANCHORE_URL = "http://anchore33-priv.novarese.net:8228/v1"
    //
    // assuming you want to use docker hub, this shouldn't need
    // any changes, but if you're using another registry, you
    // may need to tweek REPOSITORY 
    REPOSITORY = "${DOCKER_HUB_USR}/jenkins-test"
    TAG = "anchore-pipeline-no-plugin-${BUILD_NUMBER}"
    //
    // don't need an IMAGELINE if we're not using the anchore plugin
    // IMAGELINE = "${REPOSITORY}${TAG} Dockerfile"
  } // end environment
  agent any
  stages {
    stage('Checkout SCM') {
      steps {
        checkout scm
      } // end steps
    } // end stage "checkout scm"
    stage('Verify Tools') {
      steps {
        sh """
          which docker
          which anchore-cli
          which /var/jenkins_home/anchorectl
          """
      } // end steps
    } // end stage "Verify Tools"
    stage('Build image and push to docker hub') {
      steps {
        script {
          // build image and record repo/tag in DOCKER_IMAGE
          // then push it to docker hub (or whatever registry)
          //
          sh """
            docker login -u ${DOCKER_HUB_USR} -p ${DOCKER_HUB_PSW}
            docker build -t ${REPOSITORY}:${TAG} --pull -f ./Dockerfile .
            docker push ${REPOSITORY}:${TAG}
          """
          // I don't like using the docker plugin but if you want to use it, here ya go
          // DOCKER_IMAGE = docker.build REPOSITORY + ":" + TAG
          // docker.withRegistry( '', HUB_CREDENTIAL ) { 
          //  DOCKER_IMAGE.push() 
          // }
        } // end script
      } // end steps
    } // end stage "build image and tag as dev"
    stage('Analyze and get evaluation via anchore-cli') {
      steps {
        script {
          // first, queue the image for analysis
          sh """
            export ANCHORE_CLI_USER=${ANCHORE_USR}
            export ANCHORE_CLI_PASS=${ANCHORE_PSW}
            export ANCHORE_CLI_URL=${ANCHORE_URL}
            anchore-cli image add ${REPOSITORY}:${TAG}
            ## next, wait for analysis to complete
            /anchore-cli image wait --timeout 120 --interval 2 ${REPOSITORY}:${TAG}
            ## let's get the vulnerability list
            anchore-cli --url ${ANCHORE_URL} --u ${ANCHORE_USR} --p ${ANCHORE_PSW} image vuln ${REPOSITORY}:${TAG} all | tee vuln.json
          """
          // now, grab the evaluation
          try {
            sh '/usr/bin/anchore-cli --url ${ANCHORE_URL} --u ${ANCHORE_USR} --p ${ANCHORE_PSW} evaluate check --detail ${REPOSITORY}:${TAG} | tee eval.json'
          } catch (err) {
            // if evaluation fails, clean up (delete the image) and fail the build
            sh 'docker rmi ${REPOSITORY}:${TAG}'
            sh 'tar -czf reports.tgz *.json'
            archiveArtifacts artifacts: 'reports.tgz', fingerprint: true
            sh 'exit 1'
          } // end try
        } // end script 
      } // end steps
    } // end stage "analyze with syft"
    //
    // THIS STAGE IS OPTIONAL
    // the purpose of this stage is to simply show that if an image passes the scan we could
    // continue the pipeline with something like "promoting" the image to production etc
    stage('Re-tag as prod and push to registry') {
      steps {
        script {
          sh """
            docker login -u ${DOCKER_HUB_USR} -p ${DOCKER_HUB_PSW}
            docker tag ${REPOSITORY}:${TAG} ${REPOSITORY}:main
            docker push ${REPOSITORY}:main
            /usr/bin/anchore-cli --url ${ANCHORE_URL} --u ${ANCHORE_USR} --p ${ANCHORE_PSW} image add ${REPOSITORY}:main
          """
          // again, I don't like the plugin, honestly not even sure this would work correctly
          // docker.withRegistry( '', HUB_CREDENTIAL) {
          //  DOCKER_IMAGE.push('prod') 
          //  // DOCKER_IMAGE.push takes the argument as a new tag for the image before pushing          
          // }
        } // end script
      } // end steps
    } // end stage "re-tag as prod"
    stage('Clean up') {
      // delete the images locally
      steps {
        sh 'docker rmi ${REPOSITORY}:${TAG} ${REPOSITORY}:prod || failure=1' 
        sh 'tar -czf reports.tgz *.json'
        archiveArtifacts artifacts: 'reports.tgz', fingerprint: true
        //
        // the "|| failure=1" at the end of this line just catches problems with the :prod
        // tag not existing if we didn't uncomment the optional "re-tag as prod" stage
        //
      } // end steps
    } // end stage "clean up"
  } // end stages
} // end pipeline
