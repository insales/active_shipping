module ActiveMerchant
  module Shipping
    class Cpcr  < Carrier
      cattr_reader :name
      @@name = "СПСР Экспресс"

      def api
        @api ||= Api.new(
          login:    @options[:login],
          icn:      @options[:icn] || @options[:login],
          password: @options[:password]
        )
      end

      delegate :authorize, :authorize!, to: :api

      TARIFF_TYPES = %w(Пеликан-стандарт Пеликан-онлайн Гепард-онлайн Зебра-онлайн)
      PACKAGE_TYPE = {
         'Документ' => 15,
         'Грузы (Товары народного потребления (без техники, ед.кол-во))' => 16,
         'Техника или электроника без ГСМ и без АКБ (ед.кол-во)' => 17,
         'Драгоценности' => 18,
         'Медикаменты и БАДы' => 19,
         'Косметика и парфюмерия' => 20,
         'Продукты питания (партия)' => 21,
         'Техника и электроника без ГСМ (партия) или с АКБ' => 22,
         'Опасные грузы' => 23,
         'Товары народного потребления (без техники, партия)' => 24
      }.freeze

      PACKAGE_TYPE_DEFAULT = PACKAGE_TYPE['Документ']

      DEFAULT_WEIGHT = 0.1

      def find_rates(origin, destination, packages, options = {})
        package = packages.first
        rate_estimation = RateEstimate.new(origin, destination, @@name, nil, currency: 'RUR')
        weight = package.kgs
        weight = DEFAULT_WEIGHT if weight < 0.001
        authorize! if @options[:login]
        tariff = api.compute_tariff @options[:tariff_type] || TARIFF_TYPES.first,
          FromCity:     options[:origin_city_id],
          ToCity:       options[:destination_city_id],
          AmountCheck:  @options[:amount_check] ? 1 : 0,
          Nature:       @options[:package_type] || PACKAGE_TYPE_DEFAULT,
          Amount:       package.value,
          Weight:       weight
        unless tariff
          raise ArgumentError.new("CPCR fail. No tariff found for #{origin.city} -> #{destination.city}")
        end
        rate_estimation.add(package, tariff['Total_Dost'])
      end
    end
  end
end

require 'active_shipping/shipping/carriers/cpcr/city'
require 'active_shipping/shipping/carriers/cpcr/api'
