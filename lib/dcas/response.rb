# __ Documentation __
# CreditCard returns are pretty straightforward. They're handled by just this class here, DcasResponse.
# ACH returns come in two stages, and they have to be handled differently, so they're defined in
# DcasAchResponse and DcasAchReturn.
# 
# A DcasResponse object has a status. That status can be one of ['I', 'A', 'G', 'D']
# These map to a GotoTransaction's statuses, which are as follows:
#   'R' => Received
#   'A' => Accepted
#   'G' => Paid
#   'D' => Declined
#   'E' => Processing Error
# Notice that the three with the stars map directly to three of a DcasResponse object's statuses.
# The fourth status, 'I', is used to denote an Informational record. These records are never intended
# to state whether a payment was accepted, declined, or paid, but rather to provide important information
# back into the system about an account, such as information that needs to be updated soon.

module DCAS
  class Response
    class << self
      def responses_in(filename_or_content)
        responses = []

        if filename_or_content !~ /\n/ && File.exists?(filename_or_content)
          filename_or_content = File.open(filename_or_content, 'rb').map {|l| l.gsub(/[\n\r]+/, "\n")}.join
        end

        CSV::Reader.parse(filecontents) do |ccrow|
          # Could be simply '9999' -- error!
          begin
            next if ccrow == ['9999']
            # Otherwise, it is in this format:
            # CC,AccountNumber,ReturnCode,ReasonDescription,CustTraceCode
            responses << new(ccrow)
          rescue # Rescue errors caused by the data in the csv.
          end
        end

        responses
      end

      # Runs the given block for each response in the given response file.
      def each_response_in(filename_or_content)
        raise ArgumentError, "must include a block!" unless block_given?
        responses_in(filename_or_content).each do |response|
          yield response
        end
      end
    end

    attr_accessor :account_number, :check_number, :client_id, :status, :information, :description, :ach_submitted
    def attributes
      at = {}
      instance_variables.each do |iv|
        iv.gsub!('@', '')
        at[iv] = instance_variable_get("@#{iv}")
      end
      at
    end
    def attributes=(new_attributes)
      return if new_attributes.nil?
      with(new_attributes.dup) do |a|
        a.stringify_keys!
        a.each {|k,v| send(k + "=", a.delete(k)) if respond_to?("#{k}=")}
      end
    end

    # Tells if the payment was invalid. By default it's just false, but child classes can redefine this.
    def invalid?
      false
    end

    CC_RET_CODES = {
      '0' => 'D',
      '1' => 'G',
      '2' => 'I', # I think, we should never get this status. (Haven't yet...)
      '99' => 'E' # These are always server errors
    }

    def initialize(attrs={})
      new_attrs = {}
      nattrs = attrs.dup
      if nattrs.is_a?(Hash) # Is xml-hash
        nattrs.stringify_keys!
        # status, order_number, transacted_at, transaction_id, description
        new_attrs = nattrs
      elsif nattrs.respond_to?('[]') # Is csv row
        # GotoBilling: MerchantID,FirstName,LastName,CustomerID,Amount,SentDate,SettleDate,TransactionID,TransactionType,Status,Description
        # DCAS:        CC,AccountNumber,ReturnCode,ReasonDescription,ConfirmationNumber
        # ret could be 0 (denied), 1 (approved), 2 (call for authorization), or 99 (error)
        new_attrs = {
          :status => (nattrs[2].to_s == 'I' ? 'R' : CC_RET_CODES[nattrs[2].to_s]),
          :description => nattrs[3],
          :account_number => nattrs[1],
          :client_id    => nattrs[4][4..-1]
        }
        # This is the case where Malibu must call DCAS for authorization. We haven't come across that need yet, but a note should be made.
        # I'll make it an informational and 'Received' record -- but we have no answer other than this. The transaction won't go through without attention.
        new_attrs[:information] = "MUST CALL FOR Credit Card payment authorization! If you have any questions ask your Manager or the tech guy." if nattrs[2].to_s == 'I'
      end
      self.attributes = new_attrs
    end
  
    # def transaction
    #   @transaction ||= GotoTransaction.find_by_batch_id_and_client_id(self.batch_id, client_id)
    # end

    # def record_to_transaction!
    #   return unless transaction.status != status && transaction.description != description
    #   if transaction.transaction_id.to_i != 0 && transaction.status == 'G' && status == 'D'
    #     # Was accepted, now declined.
    #     # Delete the transaction if it was previously created.
    #     puts "Previously accepted, now declined: delete transaction on master, remove association on goto_transaction"
    #     # Helios::Transact.update_on_master(self.transaction.transaction_id, :CType => 1, :client_no => self.transaction_id)
    #     transaction.transaction_id = 0
    #   end
    #   transaction.description = description
    #   transaction.status = status
    #   transaction.ach_submitted = ach_submitted if ach_submitted
    #   transaction.save
    # end
  end
end
