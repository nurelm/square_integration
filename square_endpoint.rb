require 'sinatra'
require 'endpoint_base'

require './lib/square/resource'
Dir['./lib/**/*.rb'].each &method(:require)

class SquareEndpoint < EndpointBase::Sinatra::Base
  set :logging, true

  Honeybadger.configure do |config|
    config.api_key = ENV['HONEYBADGER_KEY']
    config.environment_name = ENV['RACK_ENV']
  end

  post '/get_orders' do
    renew_token!

    orders, timestamp = Square::Order.new(square_client).all(@config['square_poll_order_timestamp'])

    orders.each {|order| add_object "order", order }

    summary = nil
    if orders.any?
      summary = "#{orders.size} orders were retrieved from Square."
    end

    if timestamp.present?
      add_parameter "square_poll_order_timestamp", timestamp.iso8601
    end

    result 200, summary
  end

  post '/get_products' do
    renew_token!

    products, inventories = Square::Product.new(square_client).all

    products.each {|product| add_object 'product', product }
    inventories.each {|inventory| add_object 'inventory', inventory }

    summary = nil
    if products.any?
      summary = "#{products.size} products and #{inventories.size} inventories were retrieved from Square."
    end

    result 200, summary
  end

  post '/get_inventory' do
    renew_token!

    inventories = Square::Inventory.new(square_client).all

    inventories.each {|inventory| add_object 'inventory', inventory }

    result 200, "Received #{inventories.size} inventories from Square"
  end

  post '/set_inventory' do
    renew_token!

    summary = Square::Inventory.new(square_client).set(@payload[:inventory])

    result 200, summary
  end

  post %r{/(add|update)_product} do
    renew_token!

    summary = Square::Product.new(square_client).add_or_update(@payload[:product])

    result 200, summary
  end

  post '/update_shipment' do
    renew_token!

    Square::Order.new(square_client).update(@payload['shipment'])

    result 200, "Shipment info for order #{@payload['shipment']['order_id']} updated in square"
  end

  # Attempts to renew token on request to endpoint
  def renew_token!
    token = square_client.renew_token(@config['square_token'])

    @payload['square_token'] = token
    add_parameter 'square_token', token
  end

  def square_client
    Square::Client.new(@config['square_merchant_id'],
                       @config['square_token'])
  end
end
