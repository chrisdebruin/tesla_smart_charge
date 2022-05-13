require 'tesla_api'
require 'rest-client'
require 'json'
require 'dotenv'
require_relative 'lib/power_production'
require_relative 'lib/car'
require_relative 'models'

Dotenv.load

MIN_AMPS = 1

def reset
  AuthToken.delete_all
  AuthToken.create(access_token: ENV['TESLA_AUTH_TOKEN'], refresh_token: ENV['TESLA_AUTH_REFRESH_TOKEN'])
end

def tesla_api
  auth_token = AuthToken.last
  @tesla_api ||= TeslaApi::Client.new(access_token: auth_token.access_token, refresh_token: auth_token.refresh_token)
end

car = Car.new(tesla_api)

begin
  puts "Car state #{car.state}"

  # find_car.charge_stop

  if car.state != 'online'
    Status.create(car_status: 'offline')
    puts 'car offline, exit'
    exit
  end

  case car.charge_state
  when 'Stopped'
    puts 'Charging stopped, start charging'
    Status.create(car_status: 'online', charge_amps: MIN_AMPS)

    car.set_charging_amps(MIN_AMPS)
    car.charge_start
    exit
  when 'Charging'
    current_amps = car.charge_amps
    # divide by 2 cause we have 2 phases
    amps_production = PowerProduction.current_amps / 2
    new_amps = (amps_production + current_amps).to_i

    puts "current_amps: #{current_amps} amps_production: #{amps_production} new_amps: #{new_amps}"
    # Status.create(car_status: 'online', charge_amps: current_amps, charging_state: charge_state, production_amps: calc_amps)

    if amps_production == 0
      new_amps = current_amps - 1
    end

    if new_amps != current_amps
      puts "set amps to #{new_amps}"
      car.set_charging_amps(new_amps)
    else
      puts 'amps not changed'
    end

  else
    Status.create(car_status: 'online', charging_state: car.charge_state)
    puts "Charge state: #{car.charge_state}"
  end
rescue Faraday::ClientError => e
  puts 'vehicle unavailable' if e.response[:status] == 408
rescue Faraday::UnauthorizedError => e
  puts e.message

  tesla_api.refresh_access_token

  AuthToken.create(access_token: tesla_api.access_token, refresh_token: tesla_api.refresh_token)

  puts "access_token #{tesla_api.access_token} refresh token: #{tesla_api.refresh_token}"
rescue StandardError => e
  puts e.message
end
