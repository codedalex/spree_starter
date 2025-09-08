class AddSasapayPaymentUrlToSpreeOrders < ActiveRecord::Migration[8.0]
  def change
    add_column :spree_orders, :sasapay_payment_url, :string
  end
end
