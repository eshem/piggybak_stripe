module PiggybakStripe
  module PaymentDecorator
    extend ActiveSupport::Concern

    included do
      attr_accessor :stripe_token
    
      # validates_presence_of :stripe_token, :on => :create
    
      # [:month, :year, :payment_method_id].each do |field|
      #   _validators.reject!{ |key, _| key == field }
    
      #   _validate_callbacks.reject! do |callback|
      #     callback.raw_filter.attributes == [field]
      #   end  
      # end
      
      def process(order)
        return true if !self.new_record?
        
        calculator = ::PiggybakStripe::PaymentCalculator::Stripe.new(self.payment_method)
        Stripe.api_key = calculator.secret_key
        begin
          charge = Stripe::Charge.create({
                      :amount => (order.total_due * 100).to_i,
                      :source => self.stripe_token,
                      :currency => "usd",
                      :statement_descriptor => 'vegankale.com'
                    })
            
          self.attributes = { :transaction_id => charge.id}
          return true
        rescue Stripe::CardError, Stripe::InvalidRequestError => e
          self.errors.add :payment_method_id, e.message
          return false
        end
      end
    end

    def process_params
      params.require(:process).permit(:stripe_token)
    end
  end
end
