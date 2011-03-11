require 'spec_helper'
require 'delayed/backend/active_record'

describe Delayed::Backend::ActiveRecord::Job do
  after do
    Time.zone = nil
  end

  it_should_behave_like 'a delayed_job backend'

  context "db_time_now" do
    it "should return time in current time zone if set" do
      Time.zone = 'Eastern Time (US & Canada)'
      %w(EST EDT).should include(Delayed::Job.db_time_now.zone)
    end

    it "should return UTC time if that is the AR default" do
      Time.zone = nil
      ActiveRecord::Base.default_timezone = :utc
      Delayed::Backend::ActiveRecord::Job.db_time_now.zone.should == 'UTC'
    end

    it "should return local time if that is the AR default" do
      Time.zone = 'Central Time (US & Canada)'
      ActiveRecord::Base.default_timezone = :local
      %w(CST CDT).should include(Delayed::Backend::ActiveRecord::Job.db_time_now.zone)
    end
  end

  describe "on validations" do
    context "when multiple servers is active" do
      before(:each) { Delayed::Worker.multiple_servers = true }
      it "should validate presence of server" do
        Delayed::Backend::ActiveRecord::Job.new.valid?.should be_false
      end
    end

    context "when multiple servers is deactive" do
      before(:each) { Delayed::Worker.multiple_servers = false }
      it "should not validate presence of server" do
        Delayed::Backend::ActiveRecord::Job.new.valid?.should be_true
      end
    end
  end

  describe "after_fork" do
    it "should call reconnect on the connection" do
      ActiveRecord::Base.should_receive(:establish_connection)
      Delayed::Backend::ActiveRecord::Job.after_fork
    end
  end
end
