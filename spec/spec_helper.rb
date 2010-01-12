$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'dcas'
require 'spec'
require 'spec/autorun'

Spec::Runner.configure do |config|
  
end

Fixtures = {
  :Clients => YAML.load_file('spec/fixtures/clients.yml').collect {|c| DCAS::Client.new(c) },
  :TestPayments => {
    :Ach => YAML.load_file('spec/fixtures/ach_payments.yml'),
    :CreditCard => YAML.load_file('spec/fixtures/credit_card_payments.yml')
  },
  :PaymentFiles => Dir.glob("spec/fixtures/*.csv")
}
