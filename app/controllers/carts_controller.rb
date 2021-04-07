class CartsController < ApplicationController
    before_action :authenticate_user!

    def update
        product = params[:cart][:product_id]
        quantity = params[:cart][:quantity]
        current_order.add_product(product, quantity)
        redirect_to root_url, notice: "Product added successfuly"
    end
  
    def show
      @order = current_order
    end
  
    def pay_with_paypal
      order_id = params[:cart][:order_id]
      order_total = Order.total_order(order_id)
      token = response_token(order_total)
  
      payment_method = PaymentMethod.find_by(code: "PEC")
        Payment.create(
            order_id: order_id,
            payment_method_id: payment_method.id,
            state: "processing",
            total: order_total,
            token: token
        )

  
      redirect_to EXPRESS_GATEWAY.redirect_url_for(token)
    end
  
    def process_paypal_payment
      token = params[:token]
      price = format_usd(details.params["order_total"].to_d)
      details = EXPRESS_GATEWAY.details_for(token)
      
      response = EXPRESS_GATEWAY.purchase(price, set_express_options(token, details.payer_id, "USD"))
  
      if response.success?
        payment = Payment.find_by(token: response.token)
        order = payment.order
        #update object states
        payment.state = "completed"
        order.state = "completed"
        ActiveRecord::Base.transaction do
        order.save!
        payment.save!
        end
    end
  end