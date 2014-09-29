require 'sinatra'
require 'endpoint_base'

Dir['./lib/**/*.rb'].each &method(:require)

class SquareEndpoint < EndpointBase::Sinatra::Base
  set :logging, true

  Honeybadger.configure do |config|
    config.api_key = ENV['HONEYBADGER_KEY']
    config.environment_name = ENV['RACK_ENV']
  end

  post %r{(add_order|update_order)$} do
    begin
      client   = Square::Client.new(@config['square_site_id'], @config['squre_app_key'], @config['square_app_token'])
      response = client.send_order(@payload[:order])
      code     = 200
      set_summary "The order #{@payload[:order][:id]} was sent to Square."
    rescue SquareEndpointError => e
      code = 500
      set_summary "Validation error has ocurred: #{e.message}"
    rescue => e
      code = 500
      error_notification(e)
    end

    process_result code
  end

  post '/get_orders' do
    begin
      client = Square::Client.new(@config['square_site_id'], @config['squre_app_key'], @config['square_app_token'])
      orders = client.get_orders(@config['square_poll_order_timestamp'])

      orders.each do |order|
        add_object "order", order
      end

      code = 200
      set_summary "#{orders.size} orders were retrieved from Square." if orders.any?
    rescue SquareEndpointError => e
      code = 500
      set_summary "Validation error has ocurred: #{e.message}"
    rescue => e
      code = 500
      error_notification(e)
    end

    process_result code
  end

  post '/get_products' do
  end

  post '/get_inventory' do
  end

  post '/get_customers' do
  end

  post %r{(add_customer|update_customer)$} do
  end


  def error_notification(error)
    log_exception(error)
    set_summary "A Square Endpoint error has ocurred: #{error.message}"
  end

end