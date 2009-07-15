require File.expand_path(File.dirname(__FILE__) + '/../../test_helper')

class BlameNotifierTest < Test::Unit::TestCase
  include FileSandbox

  def setup
    setup_sandbox

    ActionMailer::Base.deliveries = []

    @project = Project.new("myproj", FakeSourceControl.new)
    @project.path = @sandbox.root

    @build = Build.new(@project, 5)
    @sandbox.new :directory => "build-5"

    @previous_build = Build.new(@project, 4)
    @sandbox.new :directory => "build-4"

    @notifier = BlameNotifier.new
    @notifier.from = 'ci@gilt.com'

    @project.add_plugin(@notifier)
  end

  def teardown
    teardown_sandbox
  end

  def test_do_nothing_for_passing_builds
    @build.stubs(:output).returns(green_build_log)
    @notifier.build_finished(@build)
    assert_equal [], ActionMailer::Base.deliveries
  end

  def test_do_nothing_for_fixed_builds
    @notifier.build_fixed(@build, @previous_build)
    assert_equal [], ActionMailer::Base.deliveries
  end

  def test_do_nothing_if_there_are_no_new_errors
    @build.stubs(:failed?).returns(true)
    @build.stubs(:output).returns(red_build_log)
    @previous_build.stubs(:output).returns(red_build_log)

    @notifier.build_finished(@build)
    assert_equal [], ActionMailer::Base.deliveries
  end

  def test_send_email_to_changeset_emails_if_there_are_new_errors
    @build.stubs(:failed?).returns(true)
    @build.stubs(:has_new_errors?).returns(true)
    @build.stubs(:changeset_emails).returns(["roy@gilt.com", "bob@gilt.com"])
    @notifier.build_finished(@build)

    assert_equal 2, ActionMailer::Base.deliveries.size
    users = ActionMailer::Base.deliveries.map { |m| m.to }.flatten
    assert users.include?("roy@gilt.com")
    assert users.include?("bob@gilt.com")
  end

end
