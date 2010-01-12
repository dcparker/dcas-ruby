require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Dcas - Comprehensive failure frequency test" do
  it "should generate Ach payment files correctly" do
    ach_payments_file = DCAS.generate!(Fixtures[:TestPayments][:Ach].collect {|p| DCAS::AchPayment.new(p) })
    ach_payments_file.should eql(File.read('spec/fixtures/ach_payments.csv'))
  end

  it "should generate CreditCard payment files correctly" do
    credit_card_payments_file = DCAS.generate!(Fixtures[:TestPayments][:CreditCard].collect {|p| DCAS::CreditCardPayment.new(p) })
    credit_card_payments_file.should eql(File.read('spec/fixtures/credit_card_payments.csv'))
  end

  it "should be able to complete an entire mock procedure without failing" do
    lambda {
      # Depends: Fixture load of a list of DCAS logins to test
      # Depends: Fixed test files
      Fixtures[:Clients].each do |client|
        client.submit_files!(Fixtures[:PaymentFiles]).should eql(Fixtures[:PaymentFiles].length)
      end
      Fixtures[:Clients].each do |client|
        client.download_response_files!
      end
    }.should_not raise_error
  end

  # I can't fake it failing without too much extra work, so I'm just testing successes for now.
end
