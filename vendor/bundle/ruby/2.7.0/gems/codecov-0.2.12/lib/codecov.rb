# frozen_string_literal: true

require 'uri'
require 'json'
require 'net/http'
require 'simplecov'
require 'zlib'

class SimpleCov::Formatter::Codecov
  VERSION = '0.2.12'

  ### CIs
  RECOGNIZED_CIS = [
    APPVEYOR = 'Appveyor CI',
    AZUREPIPELINES = 'Azure Pipelines',
    BITBUCKET = 'Bitbucket',
    BITRISE = 'Bitrise CI',
    BUILDKITE = 'Buildkite CI',
    CIRCLE = 'Circle CI',
    CODEBUILD = 'Codebuild CI',
    CODESHIP = 'Codeship CI',
    DRONEIO = 'Drone CI',
    GITHUB = 'GitHub Actions',
    GITLAB = 'GitLab CI',
    HEROKU = 'Heroku CI',
    JENKINS = 'Jenkins CI',
    SEMAPHORE = 'Semaphore CI',
    SHIPPABLE = 'Shippable',
    SOLANO = 'Solano CI',
    TEAMCITY = 'TeamCity CI',
    TRAVIS = 'Travis CI',
    WERCKER = 'Wercker CI'
  ].freeze

  def display_header
    puts [
      '',
      '  _____          _',
      ' / ____|        | |',
      '| |     ___   __| | ___  ___ _____   __',
      '| |    / _ \ / _\`|/ _ \/ __/ _ \ \ / /',
      '| |___| (_) | (_| |  __/ (_| (_) \ V /',
      ' \_____\___/ \__,_|\___|\___\___/ \_/',
      "                               Ruby-#{VERSION}",
      ''
    ].join("\n")
  end

  def detect_ci
    ci = if (ENV['CI'] == 'True') && (ENV['APPVEYOR'] == 'True')
           APPVEYOR
         elsif !ENV['TF_BUILD'].nil?
           AZUREPIPELINES
         elsif (ENV['CI'] == 'true') && !ENV['BITBUCKET_BRANCH'].nil?
           BITBUCKET
         elsif (ENV['CI'] == 'true') && (ENV['BITRISE_IO'] == 'true')
           BITRISE
         elsif (ENV['CI'] == 'true') && (ENV['BUILDKITE'] == 'true')
           BUILDKITE
         elsif (ENV['CI'] == 'true') && (ENV['CIRCLECI'] == 'true')
           CIRCLE
         elsif ENV['CODEBUILD_CI'] == 'true'
           CODEBUILD
         elsif (ENV['CI'] == 'true') && (ENV['CI_NAME'] == 'codeship')
           CODESHIP
         elsif ((ENV['CI'] == 'true') || (ENV['CI'] == 'drone')) && (ENV['DRONE'] == 'true')
           DRONEIO
         elsif (ENV['CI'] == 'true') && (ENV['GITHUB_ACTIONS'] == 'true')
           GITHUB
         elsif !ENV['GITLAB_CI'].nil?
           GITLAB
         elsif ENV['HEROKU_TEST_RUN_ID']
           HEROKU
         elsif !ENV['JENKINS_URL'].nil?
           JENKINS
         elsif (ENV['CI'] == 'true') && (ENV['SEMAPHORE'] == 'true')
           SEMAPHORE
         elsif (ENV['CI'] == 'true') && (ENV['SHIPPABLE'] == 'true')
           SHIPPABLE
         elsif ENV['TDDIUM'] == 'true'
           SOLANO
         elsif ENV['CI_SERVER_NAME'] == 'TeamCity'
           TEAMCITY
         elsif (ENV['CI'] == 'true') && (ENV['TRAVIS'] == 'true')
           TRAVIS
         elsif (ENV['CI'] == 'true') && !ENV['WERCKER_GIT_BRANCH'].nil?
           WERCKER
         end

    if !RECOGNIZED_CIS.include?(ci)
      puts [red('x>'), 'No CI provider detected.'].join(' ')
    else
      puts "==> #{ci} detected"
    end

    ci
  end

  def build_params(ci)
    params = {
      'token' => ENV['CODECOV_TOKEN'],
      'flags' => ENV['CODECOV_FLAG'] || ENV['CODECOV_FLAGS'],
      'package' => "ruby-#{VERSION}"
    }

    case ci
    when APPVEYOR
      # http://www.appveyor.com/docs/environment-variables
      params[:service] = 'appveyor'
      params[:branch] = ENV['APPVEYOR_REPO_BRANCH']
      params[:build] = ENV['APPVEYOR_JOB_ID']
      params[:pr] = ENV['APPVEYOR_PULL_REQUEST_NUMBER']
      params[:job] = ENV['APPVEYOR_ACCOUNT_NAME'] + '/' + ENV['APPVEYOR_PROJECT_SLUG'] + '/' + ENV['APPVEYOR_BUILD_VERSION']
      params[:slug] = ENV['APPVEYOR_REPO_NAME']
      params[:commit] = ENV['APPVEYOR_REPO_COMMIT']
    when AZUREPIPELINES
      params[:service] = 'azure_pipelines'
      params[:branch] = ENV['BUILD_SOURCEBRANCH']
      params[:pull_request] = ENV['SYSTEM_PULLREQUEST_PULLREQUESTNUMBER']
      params[:job] = ENV['SYSTEM_JOBID']
      params[:build] = ENV['BUILD_BUILDID']
      params[:build_url] = "#{ENV['SYSTEM_TEAMFOUNDATIONSERVERURI']}/#{ENV['SYSTEM_TEAMPROJECT']}/_build/results?buildId=#{ENV['BUILD_BUILDID']}"
      params[:commit] = ENV['BUILD_SOURCEVERSION']
      params[:slug] = ENV['BUILD_REPOSITORY_ID']
    when BITBUCKET
      # https://confluence.atlassian.com/bitbucket/variables-in-pipelines-794502608.html
      params[:service] = 'bitbucket'
      params[:branch] = ENV['BITBUCKET_BRANCH']
      # BITBUCKET_COMMIT does not always provide full commit sha due to a bug https://jira.atlassian.com/browse/BCLOUD-19393#
      params[:commit] = (ENV['BITBUCKET_COMMIT'].length < 40 ? nil : ENV['BITBUCKET_COMMIT'])
      params[:build] = ENV['BITBUCKET_BUILD_NUMBER']
    when BITRISE
      # http://devcenter.bitrise.io/faq/available-environment-variables/
      params[:service] = 'bitrise'
      params[:branch] = ENV['BITRISE_GIT_BRANCH']
      params[:pr] = ENV['BITRISE_PULL_REQUEST']
      params[:build] = ENV['BITRISE_BUILD_NUMBER']
      params[:build_url] = ENV['BITRISE_BUILD_URL']
      params[:commit] = ENV['BITRISE_GIT_COMMIT']
      params[:slug] = ENV['BITRISEIO_GIT_REPOSITORY_OWNER'] + '/' + ENV['BITRISEIO_GIT_REPOSITORY_SLUG']
    when BUILDKITE
      # https://buildkite.com/docs/guides/environment-variables
      params[:service] = 'buildkite'
      params[:branch] = ENV['BUILDKITE_BRANCH']
      params[:build] = ENV['BUILDKITE_BUILD_NUMBER']
      params[:job] = ENV['BUILDKITE_JOB_ID']
      params[:build_url] = ENV['BUILDKITE_BUILD_URL']
      params[:slug] = ENV['BUILDKITE_PROJECT_SLUG']
      params[:commit] = ENV['BUILDKITE_COMMIT']
    when CIRCLE
      # https://circleci.com/docs/environment-variables
      params[:service] = 'circleci'
      params[:build] = ENV['CIRCLE_BUILD_NUM']
      params[:job] = ENV['CIRCLE_NODE_INDEX']
      params[:slug] = if !ENV['CIRCLE_PROJECT_REPONAME'].nil?
                        ENV['CIRCLE_PROJECT_USERNAME'] + '/' + ENV['CIRCLE_PROJECT_REPONAME']
                      else
                        ENV['CIRCLE_REPOSITORY_URL'].gsub(/^.*:/, '').gsub(/\.git$/, '')
                      end
      params[:pr] = ENV['CIRCLE_PR_NUMBER']
      params[:branch] = ENV['CIRCLE_BRANCH']
      params[:commit] = ENV['CIRCLE_SHA1']
    when CODEBUILD
      # https://docs.aws.amazon.com/codebuild/latest/userguide/build-env-ref-env-vars.html
      params[:service] = 'codebuild'
      params[:branch] = ENV['CODEBUILD_WEBHOOK_HEAD_REF'].split('/')[2]
      params[:build] = ENV['CODEBUILD_BUILD_ID']
      params[:commit] = ENV['CODEBUILD_RESOLVED_SOURCE_VERSION']
      params[:job] = ENV['CODEBUILD_BUILD_ID']
      params[:slug] = ENV['CODEBUILD_SOURCE_REPO_URL'].match(/.*github.com\/(?<slug>.*).git/)['slug']
      params[:pr] = if ENV['CODEBUILD_SOURCE_VERSION']
                      matched = ENV['CODEBUILD_SOURCE_VERSION'].match(%r{pr/(?<pr>.*)})
                      matched.nil? ? ENV['CODEBUILD_SOURCE_VERSION'] : matched['pr']
                    end
    when CODESHIP
      # https://www.codeship.io/documentation/continuous-integration/set-environment-variables/
      params[:service] = 'codeship'
      params[:branch] = ENV['CI_BRANCH']
      params[:commit] = ENV['CI_COMMIT_ID']
      params[:build] = ENV['CI_BUILD_NUMBER']
      params[:build_url] = ENV['CI_BUILD_URL']
    when DRONEIO
      # https://semaphoreapp.com/docs/available-environment-variables.html
      params[:service] = 'drone.io'
      params[:branch] = ENV['DRONE_BRANCH']
      params[:commit] = ENV['DRONE_COMMIT_SHA']
      params[:job] = ENV['DRONE_JOB_NUMBER']
      params[:build] = ENV['DRONE_BUILD_NUMBER']
      params[:build_url] = ENV['DRONE_BUILD_LINK'] || ENV['DRONE_BUILD_URL'] || ENV['CI_BUILD_URL']
      params[:pr] = ENV['DRONE_PULL_REQUEST']
      params[:tag] = ENV['DRONE_TAG']
    when GITHUB
      # https://help.github.com/en/actions/configuring-and-managing-workflows/using-environment-variables#default-environment-variables
      params[:service] = 'github-actions'
      params[:branch] = ENV['GITHUB_HEAD_REF'] || ENV['GITHUB_REF'].sub('refs/head/', '')
      # PR refs are in the format: refs/pull/7/merge for pull_request events
      params[:pr] = ENV['GITHUB_REF'].split('/')[2] unless ENV['GITHUB_HEAD_REF'].nil? || ENV['GITHUB_HEAD_REF'].empty?
      params[:slug] = ENV['GITHUB_REPOSITORY']
      params[:build] = ENV['GITHUB_RUN_ID']
      params[:commit] = ENV['GITHUB_SHA']
    when GITLAB
      # http://doc.gitlab.com/ci/examples/README.html#environmental-variables
      # https://gitlab.com/gitlab-org/gitlab-ci-runner/blob/master/lib/build.rb#L96
      # GitLab Runner v9 renamed some environment variables, so we check both old and new variable names.
      params[:service] = 'gitlab'
      params[:branch] = ENV['CI_BUILD_REF_NAME'] || ENV['CI_COMMIT_REF_NAME']
      params[:build] = ENV['CI_BUILD_ID'] || ENV['CI_JOB_ID']
      slug = ENV['CI_BUILD_REPO'] || ENV['CI_REPOSITORY_URL']
      params[:slug] = slug.split('/', 4)[-1].sub('.git', '') if slug
      params[:commit] = ENV['CI_BUILD_REF'] || ENV['CI_COMMIT_SHA']
    when HEROKU
      params[:service] = 'heroku'
      params[:branch] = ENV['HEROKU_TEST_RUN_BRANCH']
      params[:build] = ENV['HEROKU_TEST_RUN_ID']
      params[:commit] = ENV['HEROKU_TEST_RUN_COMMIT_VERSION']
    when JENKINS
      # https://wiki.jenkins-ci.org/display/JENKINS/Building+a+software+project
      # https://wiki.jenkins-ci.org/display/JENKINS/GitHub+pull+request+builder+plugin#GitHubpullrequestbuilderplugin-EnvironmentVariables
      params[:service] = 'jenkins'
      params[:branch] = ENV['ghprbSourceBranch'] || ENV['GIT_BRANCH']
      params[:commit] = ENV['ghprbActualCommit'] || ENV['GIT_COMMIT']
      params[:pr] = ENV['ghprbPullId']
      params[:build] = ENV['BUILD_NUMBER']
      params[:root] = ENV['WORKSPACE']
      params[:build_url] = ENV['BUILD_URL']
    when SEMAPHORE
      # https://semaphoreapp.com/docs/available-environment-variables.html
      params[:service] = 'semaphore'
      params[:branch] = ENV['BRANCH_NAME']
      params[:commit] = ENV['REVISION']
      params[:build] = ENV['SEMAPHORE_BUILD_NUMBER']
      params[:job] = ENV['SEMAPHORE_CURRENT_THREAD']
      params[:slug] = ENV['SEMAPHORE_REPO_SLUG']
    when SHIPPABLE
      # http://docs.shippable.com/en/latest/config.html#common-environment-variables
      params[:service] = 'shippable'
      params[:branch] = ENV['BRANCH']
      params[:build] = ENV['BUILD_NUMBER']
      params[:build_url] = ENV['BUILD_URL']
      params[:pull_request] = ENV['PULL_REQUEST']
      params[:slug] = ENV['REPO_NAME']
      params[:commit] = ENV['COMMIT']
    when SOLANO
      # http://docs.solanolabs.com/Setup/tddium-set-environment-variables/
      params[:service] = 'solano'
      params[:branch] = ENV['TDDIUM_CURRENT_BRANCH']
      params[:commit] = ENV['TDDIUM_CURRENT_COMMIT']
      params[:build] = ENV['TDDIUM_TID']
      params[:pr] = ENV['TDDIUM_PR_ID']
    when TEAMCITY
      # https://confluence.jetbrains.com/display/TCD8/Predefined+Build+Parameters
      # Teamcity does not automatically make build parameters available as environment variables.
      # Add the following environment parameters to the build configuration
      # env.TEAMCITY_BUILD_BRANCH = %teamcity.build.branch%
      # env.TEAMCITY_BUILD_ID = %teamcity.build.id%
      # env.TEAMCITY_BUILD_URL = %teamcity.serverUrl%/viewLog.html?buildId=%teamcity.build.id%
      # env.TEAMCITY_BUILD_COMMIT = %system.build.vcs.number%
      # env.TEAMCITY_BUILD_REPOSITORY = %vcsroot.<YOUR TEAMCITY VCS NAME>.url%
      params[:service] = 'teamcity'
      params[:branch] = ENV['TEAMCITY_BUILD_BRANCH']
      params[:build] = ENV['TEAMCITY_BUILD_ID']
      params[:build_url] = ENV['TEAMCITY_BUILD_URL']
      params[:commit] = ENV['TEAMCITY_BUILD_COMMIT']
      params[:slug] = ENV['TEAMCITY_BUILD_REPOSITORY'].split('/', 4)[-1].sub('.git', '')
    when TRAVIS
      # http://docs.travis-ci.com/user/ci-environment/#Environment-variables
      params[:service] = 'travis'
      params[:branch] = ENV['TRAVIS_BRANCH']
      params[:pull_request] = ENV['TRAVIS_PULL_REQUEST']
      params[:job] = ENV['TRAVIS_JOB_ID']
      params[:slug] = ENV['TRAVIS_REPO_SLUG']
      params[:build] = ENV['TRAVIS_JOB_NUMBER']
      params[:commit] = ENV['TRAVIS_COMMIT']
      params[:env] = ENV['TRAVIS_RUBY_VERSION']
    when WERCKER
      # http://devcenter.wercker.com/articles/steps/variables.html
      params[:service] = 'wercker'
      params[:branch] = ENV['WERCKER_GIT_BRANCH']
      params[:build] = ENV['WERCKER_MAIN_PIPELINE_STARTED']
      params[:slug] = ENV['WERCKER_GIT_OWNER'] + '/' + ENV['WERCKER_GIT_REPOSITORY']
      params[:commit] = ENV['WERCKER_GIT_COMMIT']
    end

    if params[:branch].nil?
      # find branch, commit, repo from git command
      branch = `git rev-parse --abbrev-ref HEAD`.strip
      params[:branch] = branch != 'HEAD' ? branch : 'master'
    end

    if !ENV['VCS_COMMIT_ID'].nil?
      params[:commit] = ENV['VCS_COMMIT_ID']

    elsif params[:commit].nil?
      params[:commit] = `git rev-parse HEAD`.strip
    end

    slug = ENV['CODECOV_SLUG']
    params[:slug] = slug unless slug.nil?

    params[:pr] = params[:pr].sub('#', '') unless params[:pr].nil?

    params
  end

  def retry_request(req, https)
    retries = 3
    begin
      response = https.request(req)
    rescue Timeout::Error, SocketError => e
      retries -= 1

      if retries.zero?
        puts 'Timeout or connection error uploading coverage reports to Codecov. Out of retries.'
        puts e
        return response
      end

      puts 'Timeout or connection error uploading coverage reports to Codecov. Retrying...'
      puts e
      retry
    rescue StandardError => e
      puts 'Error uploading coverage reports to Codecov. Sorry'
      puts e.class.name
      puts e
      puts "Backtrace:\n\t#{e.backtrace}"
      return response
    end

    response
  end

  def create_report(report)
    result = {
      'meta' => {
        'version' => 'codecov-ruby/v' + VERSION
      }
    }
    result.update(result_to_codecov(report))
    result
  end

  def gzip_report(report)
    puts [green('==>'), 'Gzipping contents'].join(' ')

    io = StringIO.new
    gzip = Zlib::GzipWriter.new(io)
    gzip << report
    gzip.close

    io.string
  end

  def upload_to_codecov(ci, report)
    url = ENV['CODECOV_URL'] || 'https://codecov.io'
    is_enterprise = url != 'https://codecov.io'

    params = build_params(ci)
    params_secret_token = params.clone
    params_secret_token['token'] = 'secret'

    query = URI.encode_www_form(params)
    query_without_token = URI.encode_www_form(params_secret_token)

    gzipped_report = gzip_report(report['codecov'])

    report['params'] = params
    report['query'] = query

    puts [green('==>'), 'Uploading reports'].join(' ')
    puts "    url:   #{url}"
    puts "    query: #{query_without_token}"

    response = false
    unless is_enterprise
      response = upload_to_v4(url, gzipped_report, query, query_without_token)
      return false if response == false
    end

    response || upload_to_v2(url, gzipped_report, query, query_without_token)
  end

  def upload_to_v4(url, report, query, query_without_token)
    uri = URI.parse(url.chomp('/') + '/upload/v4')
    https = Net::HTTP.new(uri.host, uri.port)
    https.use_ssl = !url.match(/^https/).nil?

    puts [green('-> '), 'Pinging Codecov'].join(' ')
    puts "#{url}#{uri.path}?#{query_without_token}"

    req = Net::HTTP::Post.new(
      "#{uri.path}?#{query}",
      {
        'X-Reduced-Redundancy' => 'false',
        'X-Content-Encoding' => 'application/x-gzip',
        'Content-Type' => 'text/plain'
      }
    )
    response = retry_request(req, https)
    if !response&.code || response.code == '400'
      puts red(response&.body)
      return false
    end

    reports_url = response.body.lines[0]
    s3target = response.body.lines[1]
    puts [green('-> '), 'Uploading to'].join(' ')
    puts s3target

    uri = URI(s3target)
    https = Net::HTTP.new(uri.host, uri.port)
    https.use_ssl = true
    req = Net::HTTP::Put.new(
      s3target,
      {
        'Content-Encoding' => 'gzip',
        'Content-Type' => 'text/plain'
      }
    )
    req.body = report
    res = retry_request(req, https)
    if res&.body == ''
      {
        'uploaded' => true,
        'url' => reports_url,
        'meta' => {
          'status' => res.code
        },
        'message' => 'Coverage reports upload successfully'
      }.to_json
    else
      puts [black('-> '), 'Could not upload reports via v4 API, defaulting to v2'].join(' ')
      puts red(res&.body || 'nil')
      nil
    end
  end

  def upload_to_v2(url, report, query, query_without_token)
    uri = URI.parse(url.chomp('/') + '/upload/v2')
    https = Net::HTTP.new(uri.host, uri.port)
    https.use_ssl = !url.match(/^https/).nil?

    puts [green('-> '), 'Uploading to Codecov'].join(' ')
    puts "#{url}#{uri.path}?#{query_without_token}"

    req = Net::HTTP::Post.new(
      "#{uri.path}?#{query}",
      {
        'Accept' => 'application/json',
        'Content-Encoding' => 'gzip',
        'Content-Type' => 'text/plain',
        'X-Content-Encoding' => 'gzip'
      }
    )
    req.body = report
    res = retry_request(req, https)
    res&.body
  end

  def handle_report_response(report)
    if report['result']['uploaded']
      puts "    View reports at #{report['result']['url']}"
    else
      puts red('    X> Failed to upload coverage reports')
    end
  end

  def format(result, disable_net_blockers = true)
    net_blockers(:off) if disable_net_blockers

    display_header
    ci = detect_ci
    report = create_report(result)
    response = upload_to_codecov(ci, report)
    if response == false
      report['result'] = { 'uploaded' => false }
      return report
    end

    report['result'] = JSON.parse(response)
    handle_report_response(report)

    net_blockers(:on) if disable_net_blockers
    report
  end

  private

  # Format SimpleCov coverage data for the Codecov.io API.
  #
  # @param result [SimpleCov::Result] The coverage data to process.
  # @return [Hash]
  def result_to_codecov(result)
    {
      'codecov' => result_to_codecov_report(result),
      'coverage' => result_to_codecov_coverage(result),
      'messages' => result_to_codecov_messages(result)
    }
  end

  def result_to_codecov_report(result)
    report = file_network.join("\n").concat("\n")
    report = report.concat({ 'coverage' => result_to_codecov_coverage(result) }.to_json)
    report
  end

  def file_network
    invalid_file_types = [
      'woff', 'eot', 'otf', # fonts
      'gif', 'png', 'jpg', 'jpeg', 'psd', # images
      'ptt', 'pptx', 'numbers', 'pages', 'md', 'txt', 'xlsx', 'docx', 'doc', 'pdf', 'csv', # docs
      'yml', 'yaml', '.gitignore'
    ].freeze

    invalid_directories = [
      'node_modules/',
      'public/',
      'storage/',
      'tmp/',
      'vendor/'
    ]

    puts [green('==>'), 'Appending file network'].join(' ')
    network = []
    Dir['**/*'].keep_if do |file|
      if File.file?(file) && !file.end_with?(*invalid_file_types) && invalid_directories.none? { |dir| file.include?(dir) }
        network.push(file)
      end
    end

    network.push('<<<<<< network')
    network
  end

  # Format SimpleCov coverage data for the Codecov.io coverage API.
  #
  # @param result [SimpleCov::Result] The coverage data to process.
  # @return [Hash<String, Array>]
  def result_to_codecov_coverage(result)
    result.files.each_with_object({}) do |file, memo|
      memo[shortened_filename(file)] = file_to_codecov(file)
    end
  end

  # Format SimpleCov coverage data for the Codecov.io messages API.
  #
  # @param result [SimpleCov::Result] The coverage data to process.
  # @return [Hash<String, Hash>]
  def result_to_codecov_messages(result)
    result.files.each_with_object({}) do |file, memo|
      memo[shortened_filename(file)] = file.lines.each_with_object({}) do |line, lines_memo|
        lines_memo[line.line_number.to_s] = 'skipped' if line.skipped?
      end
    end
  end

  # Format coverage data for a single file for the Codecov.io API.
  #
  # @param file [SimpleCov::SourceFile] The file to process.
  # @return [Array<nil, Integer>]
  def file_to_codecov(file)
    # Initial nil is required to offset line numbers.
    [nil] + file.lines.map do |line|
      if line.skipped?
        nil
      else
        line.coverage
      end
    end
  end

  # Get a filename relative to the project root. Based on
  # https://github.com/colszowka/simplecov-html, copyright Christoph Olszowka.
  #
  # @param file [SimeplCov::SourceFile] The file to use.
  # @return [String]
  def shortened_filename(file)
    file.filename.gsub(/^#{SimpleCov.root}/, '.').gsub(%r{^\./}, '')
  end

  # Toggle VCR and WebMock on or off
  #
  # @param switch Toggle switch for Net Blockers.
  # @return [Boolean]
  def net_blockers(switch)
    throw 'Only :on or :off' unless %i[on off].include? switch

    if defined?(VCR)
      case switch
      when :on
        VCR.turn_on!
      when :off
        VCR.turn_off!(ignore_cassettes: true)
      end
    end

    if defined?(WebMock)
      # WebMock on by default
      # VCR depends on WebMock 1.8.11; no method to check whether enabled.
      case switch
      when :on
        WebMock.enable!
      when :off
        WebMock.disable!
      end
    end

    true
  end

  # Convenience color methods
  def black(str)
    str.nil? ? '' : "\e[30m#{str}\e[0m"
  end

  def red(str)
    str.nil? ? '' : "\e[31m#{str}\e[0m"
  end

  def green(str)
    str.nil? ? '' : "\e[32m#{str}\e[0m"
  end
end
