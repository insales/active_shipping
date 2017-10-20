module ActiveShipping
  class BogusCarrier < Carrier
    cattr_reader :carrier_name
    @@carrier_name = "Bogus Carrier"

    def find_rates(origin, destination, packages, options = {})
      origin = Location.from(origin)
      destination = Location.from(destination)
      packages = Array(packages)
    end
  end
end
