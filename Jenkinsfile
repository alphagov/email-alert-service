#!/usr/bin/env groovy

REPOSITORY = 'email-alert-service'

node {
  def govuk = load '/var/lib/jenkins/groovy_scripts/govuk_jenkinslib.groovy'

  properties([
    buildDiscarder(
      logRotator(
        numToKeepStr: '10')
      ),
    [$class: 'RebuildSettings', autoRebuild: false, rebuildDisabled: false],
    [$class: 'ThrottleJobProperty',
      categories: [],
      limitOneJobWithMatchingParams: true,
      maxConcurrentPerNode: 1,
      maxConcurrentTotal: 0,
      paramsToUseForLimit: REPOSITORY,
      throttleEnabled: true,
      throttleOption: 'category'],
  ])

  try {
    stage("Checkout") {
      checkout scm
    }

    stage("git merge") {
      govuk.mergeMasterBranch()
    }

    stage("bundle install") {
      govuk.bundleApp()
    }

    stage("Delete queue") {
      sh("GOVUK_ENV=test bundle exec bin/delete_queue")
    }

    stage("Run tests") {
      sh("GOVUK_ENV=test bundle exec rspec spec/")
    }

    stage("Push release tag") {
      govuk.pushTag(REPOSITORY, env.BRANCH_NAME, 'release_' + env.BUILD_NUMBER)
    }

    govuk.deployIntegration(REPOSITORY, env.BRANCH_NAME, 'release', 'deploy')

  } catch (e) {
    currentBuild.result = "FAILED"
    step([$class: 'Mailer',
          notifyEveryUnstableBuild: true,
          recipients: 'govuk-ci-notifications@digital.cabinet-office.gov.uk',
          sendToIndividuals: true])
    throw e
  }
}
