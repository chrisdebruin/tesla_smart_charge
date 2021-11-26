require 'tesla_api'
require 'rest-client'
require 'json'
require 'dotenv'

Dotenv.load

MIN_AMPS = 5

def calc_amps
  response = RestClient.get("#{ENV['HASS_HOST']}/api/states/sensor.power_production",
                            { 'Authorization' => "Bearer #{ENV['HASS_API_KEY']}",
                              'Content-Type' => 'application/json' })

  data = JSON.parse(response.body)

  kwh = data['state'].to_f

  (kwh * 1000) / 240
end

def find_car
  tesla_api = TeslaApi::Client.new(access_token: ENV['ACCESS_TOKEN'], refresh_token: ENV['REFRESH_TOKEN'])

  @find_car ||= begin
    car = tesla_api.vehicles.first

    p "found car with name #{car.vehicle['display_name']}"

    car
  end
end

begin
  # divide by 2 cause we have 2 phases
  new_amps = calc_amps / 2

  return if new_amps < 1

  charge_state = find_car.charge_state

  return unless charge_state['charging_state'] == 'Connected'

  p "set amps to #{MIN_AMPS + new_amps}"
  find_car.set_charging_amps(MIN_AMPS + new_amps)
rescue Faraday::ClientError => e
  p 'vehicle unavailable, not charging' if e.response[:status] == 408
end
