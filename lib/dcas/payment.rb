require 'fastercsv'

module DCAS
  class PaymentBatch
    def initialize(client, batch_id)
      @client = client
      @batch_id = batch_id
    end

    attr_reader :batch_id

    def payments
      @payments ||= []
    end

    def <<(payment)
      raise ArgumentError, "payment should be instance of Payment" unless payment.is_a?(Payment)
      type = payments.first.class
      raise ArgumentError, "payment added to a #{type} batch should be a #{type} but was #{payment.class.name}!" if !payments.empty? && !payment.is_a?(type)
      payment.batch = self
      payments << payment
    end

    # Generates a payment batch file and returns its contents.
    def to_csv
      FasterCSV.generate do |csv|
        csv << [ 'HD', @client.company_alias, @client.company_username, @client.company_password, 'Check' ]
        payments.each do |payment|
          csv << payment.to_csv_data if payment.batch == self # Safety net in case the same payment was applied to more than one batch. It will only go through in the last batch it was added to.
        end
      end
    end
  end

  class Payment
    attr_accessor :batch

    def initialize(client_id, client_name, amount, *args)
      @client_id = client_id
      @client_name = client_name
      @amount = amount
      @txn_type = 'Debit'
      return args
    end
  end

  class AchPayment < Payment
    # Arguments: client_id, client_name, amount, account_type, routing_number, account_number, check_number
    def initialize(*args)
      @account_type, @routing_number, @account_number, @check_number = *super
    end

    def to_csv_data(options={})
      # Example from DCAS:
          # HD,CompanyName,UserName,Password,Check
          # CA,111000753,1031103,42676345,50.99,,Darwin Rogers,1409 N AVE,,,75090,,,,,2919,,,,,Checking,,,,,,200
          # CC,VISA,4118000000981234,04/2009,19.99,N,,162078,JACLYN ,545 Sheridan Ave,,,07203,,,,9872,,,2,3,1
      [ # This is for bank account transactions
        'CA',
        @routing_number,
        @account_number,
        @check_number, # check number field can be used to prevent duplicates
        @amount,
        nil, # invoice number
        @client_name,
        nil, # address - API says required, but it's really not.
        nil, # city
        nil, # state
        nil, # zip
        nil, # phone number
        nil, # driver license number
        nil, # driver license state
        nil, # third party check? 1=yes, 0=no
        "#{@batch.batch_id}#{@client_id}", # CustTraceCode
        nil, # image name
        nil, # back image name
        @txn_type, # Credit/Debit (default Debit)
        nil, # Internal Account Number: date (in 4 digits: YYMM) + client id
        @account_type,
        #, nil, # ECC - Default Entry Class Code (??)
        # nil, nil, nil, nil, # Deposit info
        # nil, # CPA Code
        # nil, nil, # scanned MICR info
        # nil, nil # endorsement and image
      ]
    end
  end

  class AchRefund < AchPayment
    # Arguments: client_id, client_name, amount, account_type, routing_number, account_number, check_number
    def initialize(*args)
      super
      @txn_type = 'Credit'
    end
  end

  class CreditCardPayment < Payment
    # Arguments: client_id, client_name, amount, card_type, credit_card_number, expiration
    def initialize(*args)
      @card_type, @credit_card_number, @expiration = *super
    end

    def to_csv_data(options={})
      # DCAS Example:
          # HD,CompanyName,UserName,Password,CHECK 
          # CA,111000753,1031103,42676345,50.99,,Darwin Rogers,1409 N AVE,,,75090,,,,,2919,,,,,Checking,,,,,,200
          # CC,VISA,4118000000981234,04/2009,19.99,N,,162078,JACLYN ,545 Sheridan Ave,,,07203,,,,9872,,,2,3,1
      [ # This is for credit card transactions
        'CC',
        @card_type, # Card Type
        @credit_card_number, # Account Number
        @expiration, # Expiration date (MM/YYYY)
        @amount, # Amount (00.00)
        'N', # Card Present
        nil, # Card verification (if present)
        nil, # invoice number
        @client_name, # name # Larry Cummings @ DCAS Support: (972) 239-2327, ext 153 #OR# (972) 392-4654
        nil, # address
        nil, # city
        nil, # state
        nil, # zip
        nil, # phone number
        nil, # driver license number
        nil, # driver license state
        "#{@batch.batch_id}#{@client_id}", # CustTraceCode
        @txn_type, # Credit/Debit (default Debit)
        nil,
        2,
        3,
        1,
        nil
      ]
    end
  end

  class CreditCardRefund < Payment
    # Arguments: client_id, client_name, amount, card_type, credit_card_number, expiration
    def initialize(*args)
      super
      @txn_type = 'Credit'
    end
  end
end
