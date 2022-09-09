require 'json'
require 'open-uri'

def bus_board
  puts 'Hello world!'
end


class APIHandler

  def GetBusArrivals(stop)
    url = "https://api.tfl.gov.uk/StopPoint/#{stop}/Arrivals"
    response = URI.open(url).read
    json = JSON.parse(response)
    json.sort_by!{|bus| bus["timeToStation"]}
    json = json.slice(0,5)
    json.each { |bus|
      puts(bus["lineId"].to_s + " " + bus["destinationName"].to_s + " " + (bus["timeToStation"].to_i).to_s)
    }
  end

end

api = APIHandler.new()

api.GetBusArrivals("490008660N")

#Make it so that your console application takes a bus stop code as an input,
# and prints out the next 5 buses at that stop, listing each bus’s line number, destination, and minutes until arrival.
#
# 5 buses
# line number: lineId
# destination: destinationName
# minutes until arrival: timeToStation (seconds)
# #https://api.tfl.gov.uk/StopPoint/{id}/Arrivals
# #490008660N