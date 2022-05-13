class PowerProduction
  def self.current_amps
    puts "Loading current_amps"
    response = RestClient.get("#{ENV['HASS_HOST']}/api/states/sensor.power_production",
                              { 'Authorization' => "Bearer #{ENV['HASS_API_KEY']}",
                                'Content-Type' => 'application/json' })

    data = JSON.parse(response.body)

    kwh = data['state'].to_f

    ((kwh * 1000) / 240.0).round(2)
  end
end
