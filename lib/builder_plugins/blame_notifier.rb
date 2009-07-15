class BlameNotifier < BuilderPlugin

  attr_accessor :emails
  attr_accessor :from

  def initialize(project = nil)
  end

  def build_finished(build)
    if build.failed? and build.has_new_errors?
      build.changeset_emails.each do |email_address|
        email :deliver_blame_report, build, email_address
      end
    end
  end

  private

  def email(template, build, email, *args)
    begin
      BuildMailer.send(template, build, email, *args)
      CruiseControl::Log.event("Sent e-mail to #{email}", :debug)
    rescue => e
      settings = ActionMailer::Base.smtp_settings.map { |k,v| "  #{k.inspect} = #{v.inspect}" }.join("\n")
      CruiseControl::Log.event("Error sending e-mail - current server settings are :\n#{settings}", :error)
      raise
    end
  end

end

Project.plugin :blame_notifier
