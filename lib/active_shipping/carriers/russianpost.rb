require "net/http"
require "uri"

module ActiveShipping
  class Russianpost  < Carrier
    TOTAL_TIMEOUT = 3
    READ_TIMEOUT  = 3

    cattr_reader :name
    @@name = "Почта россии"

    URL = "http://kladr.insales.ru/russianpost/calculator"

    def detail_link(origin, destination, packages, options={})
      # На случае если ссылка будет находиться внутри формы,
      # форму Почты России при помощи js мы помещаем вконец body
      uri = URI.parse("#{URL}/calc")

      new_query_ar = URI.decode_www_form(uri.query || '') + get_post_options(origin, destination, packages).to_a
      uri.query = URI.encode_www_form(new_query_ar)

      uri.to_s
    end

    def get_price(origin, destination, packages)
      send_request_for_price(get_post_options(origin, destination, packages))
    end

    def find_rates(origin, destination, packages)
      if !['RU',nil].include?(destination.country_code(:alpha2))
        raise ArgumentError.new("Russianpost fail. Delivery only in russian.")
      end

      price = get_price(origin, destination, packages)

      unless price
        raise ArgumentError.new("Russianpost fail. Calculator does't return price.")
      end

      price += @options[:packing_price].to_f if @options[:packing_price]

      rate_estimation = RateEstimate.new(origin, destination, @@name, nil, currency: 'RUB')
      rate_estimation.add(packages.first, price)
    end

    private
      def get_post_options(origin, destination, packages)
        package = packages.first
        ret = {
          "src[region]"         => origin.state,
          "src[index]"          => origin.zip,
          "dst[region]"         => destination.state,
          "dst[city]"           => destination.city,
          "dst[index]"          => destination.zip,
          "package[weight]"     => (package.kgs*1000).to_i,
          "package[price]"      => package.value,
          "package[dimension]"  => @options[:dimension],
          "site"                => @options[:site]
        }
        ret["options[carefully]"] = 1 if @options[:carefully]
        ret["options[insurance]"] = 1 if @options[:insurance]
        ret
      end

      def send_request_for_price(options_hash)
        uri = URI.parse("#{URL}.json")

        result = nil
        Timeout.timeout(TOTAL_TIMEOUT) do
          http = Net::HTTP.new(uri.host, uri.port)
          http.read_timeout = READ_TIMEOUT
          if uri.scheme == 'https'
            http.use_ssl = true
            http.verify_mode = OpenSSL::SSL::VERIFY_NONE
          end

          request = Net::HTTP::Post.new(uri.request_uri)
          request.set_form_data(options_hash)

          result = http.request(request).body.to_s
        end

        price = JSON.parse(result)["price"]
        price.blank? ? nil : price.to_f
      rescue JSON::ParserError
        raise ArgumentError.new("Russianpost 500.")
      rescue Timeout::Error
        # По результатам проверки 7 таймаутов за день.
        # При таком раскладе лучше его не показывать, чем возвращать цену 0, это вызывает вопросы.
        # raise ArgumentError.new("Russianpost timeout.")
        Rails.logger.info("Russianpost timeout.")
        nil
      end
  end
end
