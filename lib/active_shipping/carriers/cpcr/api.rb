module ActiveShipping
  class Cpcr
    class Api
      class Exception < ::Exception; end
      class InvalidResponse < Exception; end
      class AuthError < Exception; end

      USER_AGENT = 'InSales'
      LOGIN_TIMEOUT = 2

      COMPUTE_TARIFF_URL = 'http://www.cpcr.ru/cgi-bin/postxml.pl?TARIFFCOMPUTE_2'
      COMPUTE_TARIFF_TIMEOUT = 3
      TARIFF_FIELDS = %w(
        TariffType
        Total_Dost
        Total_DopUsl
        Insurance
        worth
        DP
      )
      TARIFF_PRICE_FIELDS = %w(
        Total_Dost
        Total_DopUsl
        Insurance
        worth
      )

      class_attribute :test_mode
      attr_reader :sid

      def initialize(options = {})
        @options = options
      end

      def api_url
        'http://api.spsr.ru/waExec/WAExec'
      end

      def compute_tariff(*args) # type = nil, query = {}
        query = args.extract_options!
        type  = args[0]
        query.merge!(
          ICN:  @options[:icn] || @options[:login],
          SID:  sid
        )
        query_str = query.to_query.gsub '|', '%7C'
        query_str[0] &&= '&'
        url = COMPUTE_TARIFF_URL + query_str
        # puts url
        @request = RestClient::Request.new(
          method:   :get,
          url:      url,
          cookies:  @cookies,
          timeout:  COMPUTE_TARIFF_TIMEOUT
        )
        @response = @request.execute
        @cookies = @response.cookies
        response_hash = Hash.from_xml @response
        tariffs = response_hash['root'].try :[], 'Tariff'
        raise InvalidResponse.new('Invalid response: ' + @response) unless tariffs
        error = response_hash['root']['Error']
        raise Exception.new("Cpcr api error: #{error}") if error
        tariff = tariffs.is_a?(Array) ? tariffs.first : tariffs
        unless (TARIFF_FIELDS - tariff.keys).empty?
          raise InvalidResponse.new('Invalid response: ' + @response)
        end
        return tariffs.map { |x| parse_tariff_prices(x) } unless type
        tariff = tariffs.find { |x| type.in? x['TariffType'] } if tariffs.is_a?(Array)
        parse_tariff_prices(tariff)
      end

      def authorize!
        login_str = CGI.escapeHTML(@options[:login] || '')
        psw_str   = CGI.escapeHTML(@options[:password] || '')
        data = <<-XML
          <root   xmlns="http://spsr.ru/webapi/usermanagment/login/1.0">
            <p:Params Name="WALogin" Ver="1.0" xmlns:p="http://spsr.ru/webapi/WA/1.0" />
            <Login  Login="#{login_str}" Pass="#{psw_str}" UserAgent="#{USER_AGENT}" />
          </root>
        XML
        # puts data
        @request = RestClient::Request.new(
          method:   :post,
          url:      api_url,
          payload:  data,
          cookies:  @cookies,
          timeout:  LOGIN_TIMEOUT,
          headers:  {
            'Content-Type' => 'application/xml'
          }
        )
        @response = @request.execute
        @cookies = @response.cookies
        response_hash = Hash.from_xml @response
        result = response_hash['root'].try :[], 'Result'
        raise InvalidResponse.new('Invalid response: ' + @response) unless result
        raise AuthError.new("Status: #{result['RC']}") unless result['RC'] == '0'
        @sid = response_hash['root']['Login'].try :[], 'SID'
        raise InvalidResponse.new('Invalid response: ' + @response) unless @sid
      end

      def authorize
        authorize!
        true
      rescue AuthError
        false
      end

      private
        def parse_tariff_prices(tariff)
          return unless tariff
          TARIFF_PRICE_FIELDS.each do |field|
            val = tariff[field]
            tariff[field] = BigDecimal.new(val) if val
          end
          tariff
        end
    end
  end
end
