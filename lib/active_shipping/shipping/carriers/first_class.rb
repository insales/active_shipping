require "net/http"
require "uri"

module ActiveMerchant
  module Shipping
    class FirstClass < Carrier

      READ_TIMEOUT  = 3
      TOTAL_TIMEOUT = 3

      cattr_reader :name
      @@name = "Почта россии, Бандероли 1-го класса"

      URL = "http://kladr.insales.ru/first_class/calculator"

      def get_post_options(origin, packages)
        {
          "src[region]"      => origin.state,
          "src[index]"       => origin.zip,
          "cost_price"       => @options[:cost_price],
          "order_lines_json" => @options[:order_lines_json],
          "site"             => @options[:site],
          "nds"              => @options[:nds]
        }
      end

      def get_price(origin, packages)
        uri = URI.parse("#{URL}.json")

        result = nil
        Timeout.timeout(TOTAL_TIMEOUT) do
          http = Net::HTTP.new(uri.host, uri.port)
          http.read_timeout = READ_TIMEOUT
          if uri.scheme == 'https'
            http.use_ssl = true
            http.verify_mode = OpenSSL::SSL::VERIFY_NONE
          end

          request = Net::HTTP::Get.new(uri.request_uri)
          request.set_form_data(get_post_options(origin, packages))

          result = http.request(request).body.to_s
        end

        price = JSON.parse(result)["price"] rescue nil
        price.blank? ? nil : price.to_f
      rescue Timeout::Error
        raise ArgumentError.new("FirstClass timeout.")
      end

      def find_rates(origin, destination, packages)
        if !['RU',nil].include?(destination.country_code(:alpha2))
          raise ArgumentError.new("FirstClass fail. Delivery only in russian.")
        end
        if !@options[:weight_limit].blank? && packages.first.kgs > @options[:weight_limit]
          raise ArgumentError.new("FirstClass fail. Order weight exceed weight limit.")
        end

        price = get_price(origin, packages)

        unless price
          raise ArgumentError.new("FirstClass fail. Calculator does't return price.")
        end

        price += @options[:packing_price].to_f if @options[:packing_price]

        rate_estimation = RateEstimate.new(origin, @@name, nil, currency: 'RUB')
        rate_estimation.add(packages.first, price)
      end
    end
  end
end
