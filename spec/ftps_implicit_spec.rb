require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'net/ftps_implicit'

describe Net::FTPS::Implicit do
  before :all do
    @client1 = Fixtures[:Clients][0]
    @client2 = Fixtures[:Clients][1]
  end

  it "should login and logout 10 times in sequence without problems" do
    20.times do
      lambda {
        ftp = Net::FTPS::Implicit.new(DCAS::BUCKET_HOST, @client1.username, @client1.password)
        ftp.abort
        ftp.quit
        ftp.close
        ftp.should be_closed
      }.should_not raise_error
    end
  end

  it "should be able to complete a pretty comprehensive sequence in many accounts in parallel, without problems" do
    lambda {
      5.times do
        clients = Fixtures[:Clients].collect {|c| Net::FTPS::Implicit.new(DCAS::BUCKET_HOST, c.username, c.password) }
        clients.each do |c|
          c.mkdir(DCAS::STAGING_BUCKET) unless c.nlst.include?(DCAS::STAGING_BUCKET)
          c.chdir(DCAS::STAGING_BUCKET)
        end
        10.times do |i|
          clients.each do |c|
            c.put("spec/fixtures/test_upload#{i}.txt", "test_upload#{i}.txt")
          end
        end
        10.times do |i|
          clients.each do |c|
            c.delete("test_upload#{i}.txt")
          end
        end
        clients.each do |c|
          c.abort
          c.quit
          c.close
        end
      end
    }.should_not raise_error
  end
end
