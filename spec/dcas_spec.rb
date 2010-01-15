require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Dcas - Comprehensive failure frequency test" do
  before :all do
    DCAS::TESTING = true
    @fake_client = DCAS::Client.new(
      :username => 'none',
      :password => 'none',
      :company_alias => 'tester',
      :company_username => 'tester1',
      :company_password => 'fakeness1',
      :cache_location => 'none'
    )
  end

  it "should generate Ach payment files correctly" do
    ach_batch = @fake_client.new_batch('1001')
    Fixtures[:TestPayments][:Ach].collect {|p| ach_batch << DCAS::AchPayment.new(*p) }
    ach_payments_file = ach_batch.to_csv
    ach_payments_file.should eql(File.read('spec/fixtures/ach_payments.csv'))
  end

  it "should generate CreditCard payment files correctly" do
    cc_batch = @fake_client.new_batch('1001')
    Fixtures[:TestPayments][:CreditCard].collect {|p| cc_batch << DCAS::CreditCardPayment.new(*p) }
    cc_payments_file = cc_batch.to_csv
    cc_payments_file.should eql(File.read('spec/fixtures/credit_card_payments.csv'))
  end

  it "should be able to complete an entire mock procedure without failing" do
    lambda {
      # Depends: Fixture load of a list of DCAS logins to test
      # Depends: Fixed test files
      Fixtures[:Clients].each do |client|
        cc_batch = client.new_batch('123')
        Fixtures[:TestPayments][:CreditCard].each {|p| cc_batch << DCAS::CreditCardPayment.new(*p) }

        ach_batch = client.new_batch('123')
        Fixtures[:TestPayments][:Ach].each {|p| ach_batch << DCAS::AchPayment.new(*p) }

        client.submit_batches!.should eql(Fixtures[:PaymentFiles].length)
      end
      Fixtures[:Clients].each do |client|
        client.download_response_files!
      end
    }.should_not raise_error
  end

  # I can't fake it failing without too much extra work, so I'm just testing successes for now.
end
