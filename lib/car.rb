class Car
  attr_reader :tesla_api

  def initialize(tesla_api)
    @tesla_api = tesla_api
  end

  def state
    find_car.vehicle['state']
  end

  def charge_state
    find_car.charge_state['charging_state']
  end

  def set_charging_amps(amps)
    find_car.set_charging_amps(amps)
  end

  def charge_start
    find_car.charge_start
  end

  def charge_amps
    find_car.charge_state['charge_amps']
  end

  private

  def find_car
    @find_car ||= begin
      car = tesla_api.vehicles.first

      puts "found car with name #{car.vehicle['display_name']}"

      car
    rescue Faraday::UnauthorizedError => e
      puts "Car errors: #{e.message} #{AuthToken.last.inspect}"

      tesla_api.refresh_access_token

      AuthToken.create(access_token: tesla_api.access_token, refresh_token: tesla_api.refresh_token)

      retry
    end
  end
end
