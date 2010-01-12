module DCAS
  class AchResponse < Response
    DESCRIPTIONS = {
      '00' => 'Processing',
      '02' => 'Account Closed',
      '03' => 'Account Closed',
      '04' => 'Stop Payment',
      '05' => 'Stop Payment',
      '10' => 'No Debits Allowed',
      '11' => 'No Checks Allowed',
      '12' => 'Account Closed',
      '14' => 'Account Closed',
      '20' => 'Insufficient Funds',
      '21' => 'Insufficient Funds',
      '22' => 'Insufficient Funds',
      '30' => 'Insufficient Funds',
      '31' => 'Insufficient Funds',
      '32' => 'Insufficient Funds',
      '33' => 'Insufficient Funds',
      '37' => 'Account Restricted',
      '80' => 'Non-DDA Participant Credit Card',
      '81' => 'Non-DDA Participant Line of Credit',
      '82' => 'Non-DDA Participant Home Equity',
      '83' => 'Non-DDA Non-Participant Credit Card / LOC',
      '84' => 'Non-DDA Participant Broker Check',
      '85' => 'Non-DDA Non-Participant Broker Check',
      '96' => 'Non-Participant',
      '97' => 'Non-Participant',
      '98' => 'Non-DDA',
      '99' => 'Account Not Located',
      '128' => 'WARNING: Authentication Required',
      '256' => 'WARNING: Account Validation Declined',
      '257' => 'WARNING: Insufficient Funds',
      '258' => 'WARNING: Account - Invalid Card',
      '259' => 'WARNING: Account - Expired Card',
      '260' => 'WARNING: Referral',
      '261' => 'WARNING: Authentication Failed',
      '262' => 'WARNING: Authentication Server Not Available',
      '1026' => 'WARNING: Account Validation Error',
      '1027' => 'WARNING: Account Validation Failure',
      '1028' => 'WARNING: Account Duplicate',
      '1029' => 'WARNING: Account - Invalid Merchant',
      '1034' => 'WARNING: Account - Invalid Transaction',
      '9001' => 'WARNING; Bank ABA not Verified',
      '9033' => 'WARNING: Insufficient Funds',
      '9097' => 'WARNING: ABA Not Valid',
      '9098' => 'WARNING: Batch not closed',
      '9099' => 'WARNING: No Batch on file',
      '9999' => 'Unspecified Error'
    }

    def initialize(batch_id,attrs={})
      new_attrs = {}
      nattrs = attrs.dup
      if nattrs.is_a?(Hash) # Is xml-hash
        nattrs.stringify_keys!
        # status, order_number, transacted_at, transaction_id, description
        new_attrs = nattrs
      elsif nattrs.respond_to?('[]') # Is csv row
        # GotoBilling: MerchantID,FirstName,LastName,CustomerID,Amount,SentDate,SettleDate,TransactionID,TransactionType,Status,Description
        # DCAS:        RT,BankABA,AccountNumber,CheckNumber,Amount,ReturnCode,Description,CustTraceCode
        # ret could be 0 (denied), 1 (approved), 2 (call for authorization), or 99 (error)
        new_attrs = {
          :status       => nattrs[3][0..0] == 'A' ? 'A' : 'D',
          :description  => DESCRIPTIONS[nattrs[3].match(/(\d+)/)[1]] + " / " + nattrs[3].split(/-/)[1], # "Processing" if everything's good
          :ach_submitted => true,
          :client_id    => nattrs[4][4..-1],
          :account_number => nattrs[2]
        }
      end
      self.attributes = new_attrs
      self.batch_id = batch_id
    end

    def record_to_transaction!
      return unless transaction.status != status && transaction.description != description
      transaction.status = status
      transaction.description = description
      transaction.ach_submitted = true if ach_submitted
      transaction.save
    end
  end
end
