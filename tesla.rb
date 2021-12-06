require 'tesla_api'
require 'rest-client'
require 'json'
require 'dotenv'
require_relative 'models'

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

def tesla_api
  @tesla_api ||= TeslaApi::Client.new(access_token: ENV['ACCESS_TOKEN'], refresh_token: ENV['REFRESH_TOKEN'])
end

def find_car
  @find_car ||= begin
    car = tesla_api.vehicles.first

    puts "found car with name #{car.vehicle['display_name']}"

    car
  end
end

begin
  puts "Car state #{find_car.vehicle['state']}"

  # find_car.charge_stop

  if find_car.vehicle['state'] != 'online'
    Status.create(car_status: 'offline')
    puts 'car offline, exit'
    exit
  end

  charge_state = find_car.charge_state['charging_state']

  case charge_state
  when 'Stopped'
    puts 'Charging stopped, start charging'
    Status.create(car_status: 'online', charge_amps: MIN_AMPS)

    find_car.set_charging_amps(MIN_AMPS)
    find_car.charge_start
    exit
  when 'Charging'
    current_amps = find_car.charge_state['charge_amps']
    # divide by 2 cause we have 2 phases
    new_amps = calc_amps / 2

    Status.create(car_status: 'online', charge_amps: current_amps, charging_state: charge_state, production_amps: calc_amps)

    if new_amps > 1
      puts "set amps to #{current_amps + new_amps}"
      find_car.set_charging_amps(current_amps + new_amps)
    else
      puts 'amps is too low, done.'
    end
  else
    Status.create(car_status: 'online', charging_state: charge_state)
    puts "Charge cable not connected #{charge_state}"
  end
rescue Faraday::ClientError => e
  puts 'vehicle unavailable' if e.response[:status] == 408
rescue Faraday::UnauthorizedError => e
  puts e.message

  tesla_api.refresh_access_token

  AuthToken.create(access_token: tesla_api.access_token, refresh_token: tesla_api.refresh_token)

  puts "access_token #{tesla_api.access_token} refresh token: #{tesla_api.refresh_token}"
end
