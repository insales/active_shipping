module ActiveMerchant
  module Shipping
    class Cpcr
      class City < ActiveRecord::Base
        self.table_name = :cpcr_cities

        class << self
          def find_by_location(location)
            find_by_region_and_city(location.state, location.city)
          end

          def region_center?(city)
            where(city: city, subzone: '*').any?
          end
        end

        def region_center
          self.class.where(region: region, subzone: '*').first
        end

        MILTIPLIER_BY_SUBZONE = {
          'A' => 1.3,
          'B' => 1.3,
          'C' => 1.3,
          'D' => 1.5,
          'E' => 2,
          'F' => 2.3,
          'G' => 2.6,
          'H' => 3.2,
          'I' => 3.9,
          'K' => 4.5
        }

        def is_center?
          subzone == '*'
        end

        def multiplier
          MILTIPLIER_BY_SUBZONE[subzone] || 1
        end
      end
    end
  end
end
