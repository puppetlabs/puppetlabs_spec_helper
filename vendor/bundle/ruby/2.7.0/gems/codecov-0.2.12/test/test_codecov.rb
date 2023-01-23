# frozen_string_literal: true

require 'helper'

class TestCodecov < Minitest::Test
  CI = SimpleCov::Formatter::Codecov.new.detect_ci

  REALENV =
    if CI == SimpleCov::Formatter::Codecov::CIRCLE
      {
        'CIRCLECI' => ENV['CIRCLECI'],
        'CIRCLE_BUILD_NUM' => ENV['CIRCLE_BUILD_NUM'],
        'CIRCLE_NODE_INDEX' => ENV['CIRCLE_NODE_INDEX'],
        'CIRCLE_PROJECT_REPONAME' => ENV['CIRCLE_PROJECT_REPONAME'],
        'CIRCLE_PROJECT_USERNAME' => ENV['CIRCLE_PROJECT_USERNAME'],
        'CIRCLE_REPOSITORY_URL' => ENV['CIRCLE_REPOSITORY_URL'],
        'CIRCLE_PR_NUMBER' => ENV['CIRCLE_PR_NUMBER'],
        'CIRCLE_BRANCH' => ENV['CIRCLE_BRANCH'],
        'CIRCLE_SHA1' => ENV['CIRCLE_SHA1']
      }
    elsif CI == SimpleCov::Formatter::Codecov::GITHUB
      {
        'GITHUB_ACTIONS' => ENV['GITHUB_ACTIONS'],
        'GITHUB_HEAD_REF' => ENV['GITHUB_HEAD_REF'],
        'GITHUB_REF' => ENV['GITHUB_REF'],
        'GITHUB_REPOSITORY' => ENV['GITHUB_REPOSITORY'],
        'GITHUB_RUN_ID' => ENV['GITHUB_RUN_ID'],
        'GITHUB_SHA' => ENV['GITHUB_SHA']
      }
    elsif CI == SimpleCov::Formatter::Codecov::TRAVIS
      {
        'TRAVIS' => ENV['TRAVIS'],
        'TRAVIS_BRANCH' => ENV['TRAVIS_BRANCH'],
        'TRAVIS_COMMIT' => ENV['TRAVIS_COMMIT'],
        'TRAVIS_REPO_SLUG' => ENV['TRAVIS_REPO_SLUG'],
        'TRAVIS_JOB_NUMBER' => ENV['TRAVIS_JOB_NUMBER'],
        'TRAVIS_PULL_REQUEST' => ENV['TRAVIS_PULL_REQUEST'],
        'TRAVIS_JOB_ID' => ENV['TRAVIS_JOB_ID']
      }
    else
      {}
    end.freeze

  def url
    ENV['CODECOV_URL'] || 'https://codecov.io'
  end

  def test_defined
    assert defined?(SimpleCov::Formatter::Codecov)
    assert defined?(SimpleCov::Formatter::Codecov::VERSION)
  end

  def stub_file(filename, coverage)
    lines = coverage.each_with_index.map do |cov, i|
      skipped = false
      if cov == :skipped
        skipped = true
        cov = 0
      end
      stub('SimpleCov::SourceFile::Line', skipped?: skipped, line_number: i + 1, coverage: cov)
    end
    stub('SimpleCov::SourceFile', filename: filename, lines: lines)
  end

  def upload(success = true)
    WebMock.enable!
    formatter = SimpleCov::Formatter::Codecov.new
    result = stub('SimpleCov::Result', files: [
                    stub_file('/path/lib/something.rb', [1, 0, 0, nil, 1, nil]),
                    stub_file('/path/lib/somefile.rb', [1, nil, 1, 1, 1, 0, 0, nil, 1, nil])
                  ])
    SimpleCov.stubs(:root).returns('/path')
    success_stubs if success
    data = formatter.format(result, false)
    puts data
    puts data['params']
    assert_successful_upload(data) if success
    WebMock.reset!
    data
  end

  def success_stubs
    stub_request(:post, %r{https:\/\/codecov.io\/upload\/v4})
      .to_return(
        status: 200,
        body: "https://codecov.io/gh/fake\n" \
              'https://storage.googleapis.com/codecov/fake'
      )
    stub_request(:put, %r{https:\/\/storage.googleapis.com\/})
      .to_return(
        status: 200,
        body: ''
      )
  end

  def assert_successful_upload(data)
    assert_equal(data['result']['uploaded'], true)
    assert_equal(data['result']['message'], 'Coverage reports upload successfully')
    assert_equal(data['meta']['version'], 'codecov-ruby/v' + SimpleCov::Formatter::Codecov::VERSION)
    assert_equal(data['coverage'].to_json, {
      'lib/something.rb' => [nil, 1, 0, 0, nil, 1, nil],
      'lib/somefile.rb' => [nil, 1, nil, 1, 1, 1, 0, 0, nil, 1, nil]
    }.to_json)
  end

  def setup
    ENV['CI'] = nil
    ENV['CIRCLECI'] = nil
    ENV['GITHUB_ACTIONS'] = nil
    ENV['TRAVIS'] = nil
  end

  def teardown
    # needed for sending this projects coverage
    ENV['APPVEYOR'] = nil
    ENV['APPVEYOR_ACCOUNT_NAME'] = nil
    ENV['APPVEYOR_BUILD_VERSION'] = nil
    ENV['APPVEYOR_JOB_ID'] = nil
    ENV['APPVEYOR_PROJECT_SLUG'] = nil
    ENV['APPVEYOR_PULL_REQUEST_NUMBER'] = nil
    ENV['APPVEYOR_REPO_BRANCH'] = nil
    ENV['APPVEYOR_REPO_COMMIT'] = nil
    ENV['APPVEYOR_REPO_NAME'] = nil
    ENV['BITBUCKET_BRANCH'] = nil
    ENV['BITBUCKET_BUILD_NUMBER'] = nil
    ENV['BITBUCKET_COMMIT'] = nil
    ENV['BITRISE_BUILD_NUMBER'] = nil
    ENV['BITRISE_BUILD_URL'] = nil
    ENV['BITRISE_GIT_BRANCH'] = nil
    ENV['BITRISE_GIT_COMMIT'] = nil
    ENV['BITRISE_IO'] = nil
    ENV['BITRISE_PULL_REQUEST'] = nil
    ENV['BITRISEIO_GIT_REPOSITORY_OWNER'] = nil
    ENV['BITRISEIO_GIT_REPOSITORY_SLUG'] = nil
    ENV['BRANCH'] = nil
    ENV['BRANCH_NAME'] = nil
    ENV['BUILD_ID'] = nil
    ENV['BUILD_NUMBER'] = nil
    ENV['BUILD_NUMBER'] = nil
    ENV['BUILD_URL'] = nil
    ENV['BUILDKITE'] = nil
    ENV['BUILDKITE_BRANCH'] = nil
    ENV['BUILDKITE_JOB_ID'] = nil
    ENV['BUILDKITE_BUILD_NUMBER'] = nil
    ENV['BUILDKITE_BUILD_URL'] = nil
    ENV['BUILDKITE_PROJECT_SLUG'] = nil
    ENV['BUILDKITE_COMMIT'] = nil
    ENV['CI'] = 'true'
    ENV['CI_BRANCH'] = nil
    ENV['CI_BUILD_ID'] = nil
    ENV['CI_BUILD_NUMBER'] = nil
    ENV['CI_BUILD_REF'] = nil
    ENV['CI_BUILD_REF_NAME'] = nil
    ENV['CI_BUILD_REPO'] = nil
    ENV['CI_BUILD_URL'] = nil
    ENV['CI_COMMIT'] = nil
    ENV['CI_COMMIT_ID'] = nil
    ENV['CI_NAME'] = nil
    ENV['CI_PROJECT_DIR'] = nil
    ENV['CI_SERVER_NAME'] = nil
    ENV['CI_SERVER_NAME'] = nil
    ENV['CIRCLE_BRANCH'] = nil
    ENV['CIRCLE_BUILD_NUM'] = nil
    ENV['CIRCLE_NODE_INDEX'] = nil
    ENV['CIRCLE_PR_NUMBER'] = nil
    ENV['CIRCLE_PROJECT_REPONAME'] = nil
    ENV['CIRCLE_PROJECT_USERNAME'] = nil
    ENV['CIRCLE_SHA1'] = nil
    ENV['CIRCLECI'] = nil
    ENV['CODEBUILD_CI'] = nil
    ENV['CODEBUILD_BUILD_ID'] = nil
    ENV['CODEBUILD_RESOLVED_SOURCE_VERSION'] = nil
    ENV['CODEBUILD_WEBHOOK_HEAD_REF'] = nil
    ENV['CODEBUILD_SOURCE_VERSION'] = nil
    ENV['CODEBUILD_SOURCE_REPO_URL'] = nil
    ENV['CODECOV_ENV'] = nil
    ENV['CODECOV_SLUG'] = nil
    ENV['CODECOV_TOKEN'] = nil
    ENV['CODECOV_URL'] = nil
    ENV['COMMIT'] = nil
    ENV['DRONE'] = nil
    ENV['DRONE_BRANCH'] = nil
    ENV['DRONE_BUILD_URL'] = nil
    ENV['DRONE_COMMIT'] = nil
    ENV['ghprbActualCommit'] = nil
    ENV['ghprbPullId'] = nil
    ENV['ghprbSourceBranch'] = nil
    ENV['GIT_BRANCH'] = nil
    ENV['GIT_COMMIT'] = nil
    ENV['GITHUB_ACTIONS'] = nil
    ENV['GITHUB_REF'] = nil
    ENV['GITHUB_HEAD_REF'] = nil
    ENV['GITHUB_REPOSITORY'] = nil
    ENV['GITHUB_RUN_ID'] = nil
    ENV['GITHUB_SHA'] = nil
    ENV['GITLAB_CI'] = nil
    ENV['HEROKU_TEST_RUN_ID'] = nil
    ENV['HEROKU_TEST_RUN_BRANCH'] = nil
    ENV['HEROKU_TEST_RUN_COMMIT_VERSION'] = nil
    ENV['JENKINS_URL'] = nil
    ENV['MAGNUM'] = nil
    ENV['PULL_REQUEST'] = nil
    ENV['REPO_NAME'] = nil
    ENV['REVISION'] = nil
    ENV['SEMAPHORE'] = nil
    ENV['SEMAPHORE_BUILD_NUMBER'] = nil
    ENV['SEMAPHORE_CURRENT_THREAD'] = nil
    ENV['SEMAPHORE_REPO_SLUG'] = nil
    ENV['SHIPPABLE'] = nil
    ENV['TF_BUILD'] = nil
    ENV['TRAVIS'] = nil
    ENV['TRAVIS_BRANCH'] = nil
    ENV['TRAVIS_COMMIT'] = nil
    ENV['TRAVIS_JOB_ID'] = nil
    ENV['TRAVIS_JOB_NUMBER'] = nil
    ENV['TRAVIS_PULL_REQUEST'] = nil
    ENV['TRAVIS_REPO_SLUG'] = nil
    ENV['VCS_COMMIT_ID'] = nil
    ENV['WERCKER_GIT_BRANCH'] = nil
    ENV['WERCKER_GIT_COMMIT'] = nil
    ENV['WERCKER_GIT_OWNER'] = nil
    ENV['WERCKER_GIT_REPOSITORY'] = nil
    ENV['WERCKER_MAIN_PIPELINE_STARTED'] = nil
    ENV['WORKSPACE'] = nil

    REALENV.each_pair { |k, v| ENV[k] = v }
  end

  def test_git
    ENV['CODECOV_TOKEN'] = 'f881216b-b5c0-4eb1-8f21-b51887d1d506'
    result = upload
    assert_equal('f881216b-b5c0-4eb1-8f21-b51887d1d506', result['params']['token'])
    branch = `git rev-parse --abbrev-ref HEAD`.strip
    assert_equal(branch != 'HEAD' ? branch : 'master', result['params'][:branch])
    assert_equal(`git rev-parse HEAD`.strip, result['params'][:commit])
  end

  def test_enterprise
    stub = stub_request(:post, %r{https:\/\/example.com\/upload\/v2})
      .to_return(
        status: 200,
        body: "{\"id\": \"12345678-1234-abcd-ef12-1234567890ab\", \"message\": \"Coverage reports upload successfully\", \"meta\": { \"status\": 200 }, \"queued\": true, \"uploaded\": true, \"url\": \"https://example.com/github/codecov/codecov-bash/commit/2f6b51562b93e72c610671644fe2a303c5c0e8e5\"}"
      )

    ENV['CODECOV_URL'] = 'https://example.com'
    ENV['CODECOV_TOKEN'] = 'f881216b-b5c0-4eb1-8f21-b51887d1d506'
    result = upload
    assert_equal('f881216b-b5c0-4eb1-8f21-b51887d1d506', result['params']['token'])
    assert_equal('12345678-1234-abcd-ef12-1234567890ab', result['result']['id'])
    branch = `git rev-parse --abbrev-ref HEAD`.strip
    assert_equal(branch != 'HEAD' ? branch : 'master', result['params'][:branch])
    assert_equal(`git rev-parse HEAD`.strip, result['params'][:commit])
  end

  def test_travis
    ENV['CI'] = 'true'
    ENV['TRAVIS'] = 'true'
    ENV['TRAVIS_BRANCH'] = 'master'
    ENV['TRAVIS_COMMIT'] = 'c739768fcac68144a3a6d82305b9c4106934d31a'
    ENV['TRAVIS_JOB_ID'] = '33116958'
    ENV['TRAVIS_PULL_REQUEST'] = 'false'
    ENV['TRAVIS_JOB_NUMBER'] = '1'
    ENV['TRAVIS_REPO_SLUG'] = 'codecov/ci-repo'
    ENV['CODECOV_TOKEN'] = 'f881216b-b5c0-4eb1-8f21-b51887d1d506'
    result = upload
    assert_equal('travis', result['params'][:service])
    assert_equal('c739768fcac68144a3a6d82305b9c4106934d31a', result['params'][:commit])
    assert_equal('codecov/ci-repo', result['params'][:slug])
    assert_equal('1', result['params'][:build])
    assert_equal('33116958', result['params'][:job])
    assert_equal('false', result['params'][:pull_request])
    assert_equal('f881216b-b5c0-4eb1-8f21-b51887d1d506', result['params']['token'])
  end

  def test_codeship
    ENV['CI'] = 'true'
    ENV['CI_NAME'] = 'codeship'
    ENV['CI_BRANCH'] = 'master'
    ENV['CI_BUILD_NUMBER'] = '1'
    ENV['CI_COMMIT_ID'] = '743b04806ea677403aa2ff26c6bdeb85005de658'
    ENV['CODECOV_TOKEN'] = 'f881216b-b5c0-4eb1-8f21-b51887d1d506'
    result = upload
    assert_equal('codeship', result['params'][:service])
    assert_equal('743b04806ea677403aa2ff26c6bdeb85005de658', result['params'][:commit])
    assert_equal('1', result['params'][:build])
    assert_equal('master', result['params'][:branch])
    assert_equal('f881216b-b5c0-4eb1-8f21-b51887d1d506', result['params']['token'])
  end

  def test_buildkite
    ENV['CI'] = 'true'
    ENV['BUILDKITE'] = 'true'
    ENV['BUILDKITE_BRANCH'] = 'master'
    ENV['BUILDKITE_BUILD_NUMBER'] = '1'
    ENV['BUILDKITE_JOB_ID'] = '2'
    ENV['BUILDKITE_BUILD_URL'] = 'http://demo'
    ENV['BUILDKITE_PROJECT_SLUG'] = 'owner/repo'
    ENV['BUILDKITE_COMMIT'] = '743b04806ea677403aa2ff26c6bdeb85005de658'
    ENV['CODECOV_TOKEN'] = 'f881216b-b5c0-4eb1-8f21-b51887d1d506'
    result = upload
    assert_equal('buildkite', result['params'][:service])
    assert_equal('743b04806ea677403aa2ff26c6bdeb85005de658', result['params'][:commit])
    assert_equal('1', result['params'][:build])
    assert_equal('2', result['params'][:job])
    assert_equal('master', result['params'][:branch])
    assert_equal('owner/repo', result['params'][:slug])
    assert_equal('f881216b-b5c0-4eb1-8f21-b51887d1d506', result['params']['token'])
  end

  def test_jenkins
    ENV['JENKINS_URL'] = 'true'
    ENV['ghprbSourceBranch'] = 'master'
    ENV['BUILD_NUMBER'] = '1'
    ENV['ghprbActualCommit'] = '743b04806ea677403aa2ff26c6bdeb85005de658'
    ENV['CODECOV_TOKEN'] = 'f881216b-b5c0-4eb1-8f21-b51887d1d506'
    ENV['BUILD_URL'] = 'https://jenkins'
    ENV['ghprbPullId'] = '1'
    result = upload
    assert_equal('jenkins', result['params'][:service])
    assert_equal('743b04806ea677403aa2ff26c6bdeb85005de658', result['params'][:commit])
    assert_equal('1', result['params'][:build])
    assert_equal('1', result['params'][:pr])
    assert_equal('master', result['params'][:branch])
    assert_equal('https://jenkins', result['params'][:build_url])
    assert_equal('f881216b-b5c0-4eb1-8f21-b51887d1d506', result['params']['token'])
  end

  def test_jenkins_2
    ENV['JENKINS_URL'] = 'true'
    ENV['GIT_BRANCH'] = 'master'
    ENV['BUILD_NUMBER'] = '1'
    ENV['GIT_COMMIT'] = '743b04806ea677403aa2ff26c6bdeb85005de658'
    ENV['CODECOV_TOKEN'] = 'f881216b-b5c0-4eb1-8f21-b51887d1d506'
    ENV['BUILD_URL'] = 'https://jenkins'
    result = upload
    assert_equal('jenkins', result['params'][:service])
    assert_equal('743b04806ea677403aa2ff26c6bdeb85005de658', result['params'][:commit])
    assert_equal('1', result['params'][:build])
    assert_equal('master', result['params'][:branch])
    assert_equal('https://jenkins', result['params'][:build_url])
    assert_equal('f881216b-b5c0-4eb1-8f21-b51887d1d506', result['params']['token'])
  end

  def test_shippable
    ENV['CI'] = 'true'
    ENV['SHIPPABLE'] = 'true'
    ENV['BRANCH'] = 'master'
    ENV['BUILD_NUMBER'] = '1'
    ENV['BUILD_URL'] = 'http://shippable.com/...'
    ENV['PULL_REQUEST'] = 'false'
    ENV['REPO_NAME'] = 'owner/repo'
    ENV['COMMIT'] = '743b04806ea677403aa2ff26c6bdeb85005de658'
    ENV['CODECOV_TOKEN'] = 'f881216b-b5c0-4eb1-8f21-b51887d1d506'
    result = upload
    assert_equal('shippable', result['params'][:service])
    assert_equal('743b04806ea677403aa2ff26c6bdeb85005de658', result['params'][:commit])
    assert_equal('false', result['params'][:pull_request])
    assert_equal('1', result['params'][:build])
    assert_equal('http://shippable.com/...', result['params'][:build_url])
    assert_equal('master', result['params'][:branch])
    assert_equal('owner/repo', result['params'][:slug])
    assert_equal('f881216b-b5c0-4eb1-8f21-b51887d1d506', result['params']['token'])
  end

  def test_appveyor
    ENV['CI'] = 'True'
    ENV['APPVEYOR'] = 'True'
    ENV['APPVEYOR_REPO_BRANCH'] = 'master'
    ENV['APPVEYOR_JOB_ID'] = 'build'
    ENV['APPVEYOR_PULL_REQUEST_NUMBER'] = '1'
    ENV['APPVEYOR_ACCOUNT_NAME'] = 'owner'
    ENV['APPVEYOR_PROJECT_SLUG'] = 'repo'
    ENV['APPVEYOR_BUILD_VERSION'] = 'job'
    ENV['APPVEYOR_REPO_NAME'] = 'owner/repo'
    ENV['APPVEYOR_REPO_COMMIT'] = '743b04806ea677403aa2ff26c6bdeb85005de658'
    ENV['CODECOV_TOKEN'] = 'f881216b-b5c0-4eb1-8f21-b51887d1d506'
    result = upload
    assert_equal('appveyor', result['params'][:service])
    assert_equal('743b04806ea677403aa2ff26c6bdeb85005de658', result['params'][:commit])
    assert_equal('master', result['params'][:branch])
    assert_equal('owner/repo', result['params'][:slug])
    assert_equal('1', result['params'][:pr])
    assert_equal('build', result['params'][:build])
    assert_equal('owner/repo/job', result['params'][:job])
    assert_equal('f881216b-b5c0-4eb1-8f21-b51887d1d506', result['params']['token'])
  end

  def test_circleci
    ENV['CI'] = 'true'
    ENV['CIRCLECI'] = 'true'
    ENV['CIRCLE_BRANCH'] = 'master'
    ENV['CIRCLE_BUILD_NUM'] = '1'
    ENV['CIRCLE_NODE_INDEX'] = '2'
    ENV['CIRCLE_PR_NUMBER'] = '3'
    ENV['CIRCLE_PROJECT_USERNAME'] = 'owner'
    ENV['CIRCLE_PROJECT_REPONAME'] = 'repo'
    ENV['CIRCLE_SHA1'] = '743b04806ea677403aa2ff26c6bdeb85005de658'
    ENV['CODECOV_TOKEN'] = 'f881216b-b5c0-4eb1-8f21-b51887d1d506'
    result = upload
    assert_equal('circleci', result['params'][:service])
    assert_equal('743b04806ea677403aa2ff26c6bdeb85005de658', result['params'][:commit])
    assert_equal('1', result['params'][:build])
    assert_equal('2', result['params'][:job])
    assert_equal('3', result['params'][:pr])
    assert_equal('master', result['params'][:branch])
    assert_equal('owner/repo', result['params'][:slug])
    assert_equal('f881216b-b5c0-4eb1-8f21-b51887d1d506', result['params']['token'])
  end

  def test_semaphore
    ENV['CI'] = 'true'
    ENV['SEMAPHORE'] = 'true'
    ENV['BRANCH_NAME'] = 'master'
    ENV['SEMAPHORE_REPO_SLUG'] = 'owner/repo'
    ENV['SEMAPHORE_BUILD_NUMBER'] = '1'
    ENV['SEMAPHORE_CURRENT_THREAD'] = '2'
    ENV['REVISION'] = '743b04806ea677403aa2ff26c6bdeb85005de658'
    ENV['CODECOV_TOKEN'] = 'f881216b-b5c0-4eb1-8f21-b51887d1d506'
    result = upload
    assert_equal('semaphore', result['params'][:service])
    assert_equal('743b04806ea677403aa2ff26c6bdeb85005de658', result['params'][:commit])
    assert_equal('1', result['params'][:build])
    assert_equal('2', result['params'][:job])
    assert_equal('master', result['params'][:branch])
    assert_equal('owner/repo', result['params'][:slug])
    assert_equal('f881216b-b5c0-4eb1-8f21-b51887d1d506', result['params']['token'])
  end

  def test_drone
    ENV['CI'] = 'true'
    ENV['DRONE'] = 'true'
    ENV['DRONE_BRANCH'] = 'master'
    ENV['DRONE_BUILD_NUMBER'] = '1'
    ENV['DRONE_BUILD_URL'] = 'https://drone.io/...'
    ENV['DRONE_COMMIT'] = '1123566'
    ENV['CODECOV_SLUG'] = 'codecov/ci-repo'
    ENV['CODECOV_TOKEN'] = 'f881216b-b5c0-4eb1-8f21-b51887d1d506'
    result = upload
    assert_equal('drone.io', result['params'][:service])
    assert_equal(`git rev-parse HEAD`.strip, result['params'][:commit])
    assert_equal('1', result['params'][:build])
    assert_equal('https://drone.io/...', result['params'][:build_url])
    assert_equal('codecov/ci-repo', result['params'][:slug])
    assert_equal('master', result['params'][:branch])
    assert_equal('f881216b-b5c0-4eb1-8f21-b51887d1d506', result['params']['token'])
  end

  def test_wercker
    ENV['CI'] = 'true'
    ENV['WERCKER_GIT_BRANCH'] = 'master'
    ENV['WERCKER_MAIN_PIPELINE_STARTED'] = '1'
    ENV['WERCKER_GIT_OWNER'] = 'owner'
    ENV['WERCKER_GIT_REPOSITORY'] = 'repo'
    ENV['WERCKER_GIT_COMMIT'] = '743b04806ea677403aa2ff26c6bdeb85005de658'
    ENV['CODECOV_TOKEN'] = 'f881216b-b5c0-4eb1-8f21-b51887d1d506'
    result = upload
    assert_equal('wercker', result['params'][:service])
    assert_equal('743b04806ea677403aa2ff26c6bdeb85005de658', result['params'][:commit])
    assert_equal('1', result['params'][:build])
    assert_equal('master', result['params'][:branch])
    assert_equal('owner/repo', result['params'][:slug])
    assert_equal('f881216b-b5c0-4eb1-8f21-b51887d1d506', result['params']['token'])
  end

  def test_github_pull_request
    ENV['CI'] = 'true'
    ENV['GITHUB_ACTIONS'] = 'true'
    ENV['GITHUB_HEAD_REF'] = 'patch-2'
    ENV['GITHUB_REF'] = 'refs/pull/7/merge'
    ENV['GITHUB_REPOSITORY'] = 'codecov/ci-repo'
    ENV['GITHUB_RUN_ID'] = '1'
    ENV['GITHUB_SHA'] = 'c739768fcac68144a3a6d82305b9c4106934d31a'
    ENV['CODECOV_TOKEN'] = 'f881216b-b5c0-4eb1-8f21-b51887d1d506'
    result = upload
    assert_equal('github-actions', result['params'][:service])
    assert_equal('c739768fcac68144a3a6d82305b9c4106934d31a', result['params'][:commit])
    assert_equal('codecov/ci-repo', result['params'][:slug])
    assert_equal('1', result['params'][:build])
    assert_equal('f881216b-b5c0-4eb1-8f21-b51887d1d506', result['params']['token'])
    assert_equal('patch-2', result['params'][:branch])
    assert_equal('7', result['params'][:pr])
  end

  def test_github_push
    ENV['CI'] = 'true'
    ENV['GITHUB_ACTIONS'] = 'true'
    ENV['GITHUB_HEAD_REF'] = nil
    ENV['GITHUB_REF'] = 'refs/head/master'
    ENV['GITHUB_REPOSITORY'] = 'codecov/ci-repo'
    ENV['GITHUB_RUN_ID'] = '1'
    ENV['GITHUB_SHA'] = 'c739768fcac68144a3a6d82305b9c4106934d31a'
    ENV['CODECOV_TOKEN'] = 'f881216b-b5c0-4eb1-8f21-b51887d1d506'
    result = upload
    assert_equal('github-actions', result['params'][:service])
    assert_equal('c739768fcac68144a3a6d82305b9c4106934d31a', result['params'][:commit])
    assert_equal('codecov/ci-repo', result['params'][:slug])
    assert_equal('1', result['params'][:build])
    assert_equal('f881216b-b5c0-4eb1-8f21-b51887d1d506', result['params']['token'])
    assert_equal('master', result['params'][:branch])
    assert_equal(false, result['params'].key?(:pr))
  end

  def test_gitlab
    ENV['GITLAB_CI'] = 'true'
    ENV['CI_BUILD_REF_NAME'] = 'master'
    ENV['CI_BUILD_ID'] = '1'
    ENV['CI_BUILD_REPO'] = 'https://gitlab.com/owner/repo.git'
    ENV['CI_BUILD_REF'] = '743b04806ea677403aa2ff26c6bdeb85005de658'
    ENV['CODECOV_TOKEN'] = 'f881216b-b5c0-4eb1-8f21-b51887d1d506'
    result = upload
    assert_equal('gitlab', result['params'][:service])
    assert_equal('743b04806ea677403aa2ff26c6bdeb85005de658', result['params'][:commit])
    assert_equal('1', result['params'][:build])
    assert_equal('master', result['params'][:branch])
    assert_equal('owner/repo', result['params'][:slug])
    assert_equal('f881216b-b5c0-4eb1-8f21-b51887d1d506', result['params']['token'])
  end

  def test_bitrise
    ENV['CI'] = 'true'
    ENV['BITRISE_IO'] = 'true'
    ENV['BITRISE_BUILD_NUMBER'] = '1'
    ENV['BITRISE_BUILD_URL'] = 'https://app.bitrise.io/build/123'
    ENV['BITRISE_GIT_BRANCH'] = 'master'
    ENV['BITRISE_PULL_REQUEST'] = '2'
    ENV['BITRISEIO_GIT_REPOSITORY_OWNER'] = 'owner'
    ENV['BITRISEIO_GIT_REPOSITORY_SLUG'] = 'repo'
    ENV['BITRISE_GIT_COMMIT'] = '743b04806ea677403aa2ff26c6bdeb85005de658'
    ENV['CODECOV_TOKEN'] = 'f881216b-b5c0-4eb1-8f21-b51887d1d506'
    result = upload
    assert_equal('bitrise', result['params'][:service])
    assert_equal('1', result['params'][:build])
    assert_equal('https://app.bitrise.io/build/123', result['params'][:build_url])
    assert_equal('master', result['params'][:branch])
    assert_equal('2', result['params'][:pr])
    assert_equal('owner/repo', result['params'][:slug])
    assert_equal('743b04806ea677403aa2ff26c6bdeb85005de658', result['params'][:commit])
  end

  def test_teamcity
    ENV['CI_SERVER_NAME'] = 'TeamCity'
    ENV['TEAMCITY_BUILD_BRANCH'] = 'master'
    ENV['TEAMCITY_BUILD_ID'] = '1'
    ENV['TEAMCITY_BUILD_URL'] = 'http://teamcity/...'
    ENV['TEAMCITY_BUILD_COMMIT'] = '743b04806ea677403aa2ff26c6bdeb85005de658'
    ENV['TEAMCITY_BUILD_REPOSITORY'] = 'https://github.com/owner/repo.git'
    ENV['CODECOV_TOKEN'] = 'f881216b-b5c0-4eb1-8f21-b51887d1d506'
    result = upload
    assert_equal('teamcity', result['params'][:service])
    assert_equal('743b04806ea677403aa2ff26c6bdeb85005de658', result['params'][:commit])
    assert_equal('1', result['params'][:build])
    assert_equal('master', result['params'][:branch])
    assert_equal('owner/repo', result['params'][:slug])
    assert_equal('f881216b-b5c0-4eb1-8f21-b51887d1d506', result['params']['token'])
  end

  def test_azure_pipelines
    ENV['TF_BUILD'] = '1'
    ENV['BUILD_SOURCEBRANCH'] = 'master'
    ENV['SYSTEM_JOBID'] = '92a2fa25-f940-5df6-a185-81eb9ae2031d'
    ENV['BUILD_BUILDID'] = '1'
    ENV['SYSTEM_TEAMFOUNDATIONSERVERURI'] = 'https://dev.azure.com/codecov/'
    ENV['SYSTEM_TEAMPROJECT'] = 'repo'
    ENV['BUILD_SOURCEVERSION'] = '743b04806ea677403aa2ff26c6bdeb85005de658'
    ENV['BUILD_REPOSITORY_ID'] = 'owner/repo'
    ENV['CODECOV_TOKEN'] = 'f881216b-b5c0-4eb1-8f21-b51887d1d506'
    result = upload
    assert_equal('azure_pipelines', result['params'][:service])
    assert_equal('743b04806ea677403aa2ff26c6bdeb85005de658', result['params'][:commit])
    assert_equal('1', result['params'][:build])
    assert_equal('master', result['params'][:branch])
    assert_equal('owner/repo', result['params'][:slug])
    assert_equal('f881216b-b5c0-4eb1-8f21-b51887d1d506', result['params']['token'])
  end

  def test_heroku
    ENV['HEROKU_TEST_RUN_ID'] = '454f5dc9-afa4-433f-bb28-84678a00fd98'
    ENV['HEROKU_TEST_RUN_BRANCH'] = 'master'
    ENV['HEROKU_TEST_RUN_COMMIT_VERSION'] = '743b04806ea677403aa2ff26c6bdeb85005de658'
    ENV['CODECOV_TOKEN'] = 'f881216b-b5c0-4eb1-8f21-b51887d1d506'

    result = upload
    assert_equal('heroku', result['params'][:service])
    assert_equal('743b04806ea677403aa2ff26c6bdeb85005de658', result['params'][:commit])
    assert_equal('454f5dc9-afa4-433f-bb28-84678a00fd98', result['params'][:build])
    assert_equal('master', result['params'][:branch])
    assert_equal('f881216b-b5c0-4eb1-8f21-b51887d1d506', result['params']['token'])
  end

  def test_bitbucket_pr
    ENV['CI'] = 'true'
    ENV['BITBUCKET_BUILD_NUMBER'] = '100'
    ENV['BITBUCKET_BRANCH'] = 'master'
    ENV['BITBUCKET_COMMIT'] = '743b04806ea67'
    ENV['VCS_COMMIT_ID'] = '743b04806ea677403aa2ff26c6bdeb85005de658'
    ENV['CODECOV_TOKEN'] = 'f881216b-b5c0-4eb1-8f21-b51887d1d506'

    result = upload
    assert_equal('bitbucket', result['params'][:service])
    assert_equal('743b04806ea677403aa2ff26c6bdeb85005de658', result['params'][:commit])
    assert_equal('100', result['params'][:build])
    assert_equal('master', result['params'][:branch])
    assert_equal('f881216b-b5c0-4eb1-8f21-b51887d1d506', result['params']['token'])
  end

  def test_bitbucket
    ENV['CI'] = 'true'
    ENV['BITBUCKET_BUILD_NUMBER'] = '100'
    ENV['BITBUCKET_BRANCH'] = 'master'
    ENV['BITBUCKET_COMMIT'] = '743b04806ea677403aa2ff26c6bdeb85005de658'
    ENV['CODECOV_TOKEN'] = 'f881216b-b5c0-4eb1-8f21-b51887d1d506'

    result = upload
    assert_equal('bitbucket', result['params'][:service])
    assert_equal('743b04806ea677403aa2ff26c6bdeb85005de658', result['params'][:commit])
    assert_equal('100', result['params'][:build])
    assert_equal('master', result['params'][:branch])
    assert_equal('f881216b-b5c0-4eb1-8f21-b51887d1d506', result['params']['token'])
  end

  def test_codebuild
    ENV['CODEBUILD_CI'] = "true"
    ENV['CODEBUILD_BUILD_ID'] = "codebuild-project:458dq3q8-7354-4513-8702-ea7b9c81efb3"
    ENV['CODEBUILD_RESOLVED_SOURCE_VERSION'] = 'd653b934ed59c1a785cc1cc79d08c9aaa4eba73b'
    ENV['CODEBUILD_WEBHOOK_HEAD_REF'] = 'refs/heads/master'
    ENV['CODEBUILD_SOURCE_VERSION'] = 'pr/123'
    ENV['CODEBUILD_SOURCE_REPO_URL'] = 'https://github.com/owner/repo.git'
    ENV['CODECOV_TOKEN'] = 'f881216b-b5c0-4eb1-8f21-b51887d1d506'

    result = upload

    assert_equal("codebuild", result['params'][:service])
    assert_equal("d653b934ed59c1a785cc1cc79d08c9aaa4eba73b", result['params'][:commit])
    assert_equal("codebuild-project:458dq3q8-7354-4513-8702-ea7b9c81efb3", result['params'][:build])
    assert_equal("codebuild-project:458dq3q8-7354-4513-8702-ea7b9c81efb3", result['params'][:job])
    assert_equal("owner/repo", result['params'][:slug])
    assert_equal("master", result['params'][:branch])
    assert_equal("123", result['params'][:pr])
    assert_equal('f881216b-b5c0-4eb1-8f21-b51887d1d506', result['params']['token'])
  end

  def test_codebuild_source_version_is_other_than_pr_number
    ENV['CODEBUILD_CI'] = 'true'
    ENV['CODEBUILD_BUILD_ID'] = 'codebuild-project:458dq3q8-7354-4513-8702-ea7b9c81efb3'
    ENV['CODEBUILD_RESOLVED_SOURCE_VERSION'] = 'd653b934ed59c1a785cc1cc79d08c9aaa4eba73b'
    ENV['CODEBUILD_WEBHOOK_HEAD_REF'] = 'refs/heads/master'
    ENV['CODEBUILD_SOURCE_VERSION'] = 'git-commit-hash-12345'
    ENV['CODEBUILD_SOURCE_REPO_URL'] = 'https://github.com/owner/repo.git'
    ENV['CODECOV_TOKEN'] = 'f881216b-b5c0-4eb1-8f21-b51887d1d506'

    result = upload

    assert_equal('codebuild', result['params'][:service])
    assert_equal('d653b934ed59c1a785cc1cc79d08c9aaa4eba73b', result['params'][:commit])
    assert_equal('codebuild-project:458dq3q8-7354-4513-8702-ea7b9c81efb3', result['params'][:build])
    assert_equal('git-commit-hash-12345', result['params'][:pr])
    assert_equal('owner/repo', result['params'][:slug])
    assert_equal('master', result['params'][:branch])
    assert_equal('git-commit-hash-12345', result['params'][:pr])
    assert_equal('f881216b-b5c0-4eb1-8f21-b51887d1d506', result['params']['token'])
  end

  def test_filenames_are_shortened_correctly
    ENV['CODECOV_TOKEN'] = 'f881216b-b5c0-4eb1-8f21-b51887d1d506'

    formatter = SimpleCov::Formatter::Codecov.new
    result = stub('SimpleCov::Result', files: [
                    stub_file('/path/lib/something.rb', []),
                    stub_file('/path/path/lib/path_somefile.rb', [])
                  ])
    SimpleCov.stubs(:root).returns('/path')
    data = formatter.format(result)
    puts data
    puts data['params']
    assert_equal(data['coverage'].to_json, {
      'lib/something.rb' => [nil],
      'path/lib/path_somefile.rb' => [nil]
    }.to_json)
  end

  def test_invalid_token
    stub_request(:post, %r{https:\/\/codecov.io\/upload})
      .to_return(
        status: 400,
        body: "HTTP 400\n" \
              'Provided token is not a UUID.'
      )

    ENV['CODECOV_TOKEN'] = 'fake'
    result = upload(false)
    assert_equal(false, result['result']['uploaded'])
    branch = `git rev-parse --abbrev-ref HEAD`.strip
    assert_equal(branch != 'HEAD' ? branch : 'master', result['params'][:branch])
    assert_equal(`git rev-parse HEAD`.strip, result['params'][:commit])
  end
end
