require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Dcas - Comprehensive failure frequency test" do
  it "should be able to complete an entire mock procedure without failing" do
    clients = [] # fixture load of a list of DCAS logins to test
    files = [] # fixed test files
    clients.each do |client|
      client.submit_files!(files)
    end
    clients.each do |client|
      client.download_response_files!
    end
  end
end
