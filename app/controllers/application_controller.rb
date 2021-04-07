class ApplicationController < ActionController::Base

  def current_order
    if current_user
      order = Order.where(user_id: current_user.id).where(state: "created").last
      if order.nil?
        order = Order.create!(user: current_user, state: "created")
      end
      return order
    end

    nil
  end

  def format_usd (price)
    price * 100
  end

  def response_token(order_total)
    EXPRESS_GATEWAY.setup_purchase(format_usd(order_total),
      ip: request.remote_ip,
      return_url: process_paypal_payment_cart_url,
      cancel_return_url: root_url,
      allow_guest_checkout: true,
      currency: "USD").token
  end

  def set_express_options(token, payer_id,currency) 
    express_purchase_options =
      {
        ip: request.remote_ip,
        token: token,
        payer_id: payer_id,
        currency: currency
      }
  end

end