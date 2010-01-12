module DCAS
  class AchReturn < Response
    DESCRIPTIONS = {
      'C01' => 'Incorrect DFI account number',
      'C02' => 'Incorrect T/R number',
      'C03' => 'Incorrect T/R number and incorrect DFI account number',
      'C04' => 'Incorrect indvidual name/receiving company name',
      'C05' => 'Incorrect transaction codes',
      'C06' => 'Incorrect DFI account number and incorrect transaction code',
      'C07' => 'Incorrect T/R number, incorrect DFI number and incorrect transaction code',
      'C08' => 'Reserved',
      'C09' => 'Incorrect individual identification number',
      'C10' => 'Incorrect company name',
      'C11' => 'Incorrect',
      'C12' => 'Incorrect company name and company identification',
      'C13' => 'Addenda format error',
      'C61' => 'Misrouted notification change',
      'C62' => 'Incorrect trace number',
      'C63' => 'Incorrect company identification number',
      'C64' => 'Incorrect individual identification number/identification number',
      'C65' => 'Incorrectly formatted corrected data',
      'C66' => 'Incorrect discretionary data',
      'C67' => 'Routing number not from original entry detail record',
      'C68' => 'DFI account number not from original entry detail record',
      'C69' => 'Incorrect transaction code',
      'R01' => 'Insufficient funds',
      'R02' => 'Account closed',
      'R03' => 'No account/Unable to locate account',
      'R04' => 'Invalid account number',
      'R05' => 'Reserved',
      'R06' => 'Returned per Originating DFIs request',
      'R07' => 'Authorization revoked by customer',
      'R08' => 'Payment stopped',
      'R09' => 'Uncollected Funds',
      'R10' => 'Customer advises not authorized',
      'R11' => 'Check truncation entry return',
      'R12' => 'Branch sold to another DFI',
      'R13' => 'Receiving DFI not qualified to participate',
      'R14' => 'Account-holder deceased',
      'R15' => 'Beneficiary deceased',
      'R16' => 'Account frozen',
      'R17' => 'File record edit criteria',
      'R18' => 'Improper effective entry date',
      'R19' => 'Amount field error',
      'R20' => 'Non-transaction account',
      'R21' => 'Invalid company identification',
      'R22' => 'Invalid individual ID number',
      'R23' => 'Credit entry refused by receiver',
      'R24' => 'Duplicate entry',
      'R25' => 'Addenda error',
      'R26' => 'Mandatory field error',
      'R27' => 'Trace number error',
      'R28' => 'Transit/Routing check digit error',
      'R29' => 'Corporate customer advises not authorized',
      'R30' => 'Receiving DFI not participant in check truncation program',
      'R31' => 'Permissible return entry',
      'R32' => 'RDFI - non-settlement',
      'R33' => 'Return for XCK',
      'R34' => 'Limited participation DFI',
      '900' => 'Edit Reject',
      '901' => 'Non-Sufficient Funds',
      '902' => 'Cannot Trace',
      '903' => 'Payment Stopped/Recalled',
      '904' => 'Post/Stale Dated',
      '905' => 'Account Closed',
      '906' => 'Account Transferred',
      '907' => 'No Checquing Privileges',
      '908' => 'Funds Not Cleared',
      '910' => 'Payer/Payee Deceased',
      '911' => 'Account Frozen',
      '912' => 'Invalid/Incorrect Account Number',
      '914' => 'Incorrect Payer/Payee Name',
      '915' => 'Refused By Payer/Payee',
      '990' => 'Institution In Default',
      '998' => 'No Agreement For Returns'
    }

    ACH_RET_CODES = {
      'A' => 'G',
      'C' => 'I',
      'R' => 'D',
      '9' => 'D'
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
        status = ACH_RET_CODES[nattrs[5][0..0]]
        new_attrs = {
          :account_number => nattrs[2],
          :check_number => nattrs[3],
          :client_id    => nattrs[7] ? nattrs[7][4..-1] : nil
        }
        if status == 'I'
          new_attrs[:information] = "#{DESCRIPTIONS[nattrs[5]]} (#{nattrs[6]})"
        else
          new_attrs[:status]      = status
          new_attrs[:description] = "#{DESCRIPTIONS[nattrs[5]]} (#{nattrs[6]})"
        end
      end
      self.attributes = new_attrs
      self.batch_id = batch_id
    end
  
    def transaction
      @transaction ||= GotoTransaction.find_by_batch_id_and_client_id(self.batch_id, self.client_id)
      @transaction ||= GotoTransaction.find_by_batch_id_and_bank_account_number_and_check_number(self.batch_id, self.account_number, self.check_number)
      @transaction
    end

    def record_to_transaction!
      return unless transaction.status != status && transaction.description != description

      transaction.transaction_id = 0 if transaction.transaction_id.to_i != 0 && transaction.status == 'G' && status == 'D' # Was accepted, now declined.

      if status == 'I'
        transaction.information = information
      else
        transaction.description = description
      end
      transaction.status = status
      transaction.ach_submitted = ach_submitted if ach_submitted
      transaction.save
    end
  end
end
