require 'json'
require 'open-uri'


class APIHandler
  Coordinates = Struct.new(:latitude,:longitude)
  Bus_Stop = Struct.new(:name, :id, :distance)
  @@stop_types = %w[NaptanBusCoachStation NaptanBusWayPoint NaptanOnstreetBusCoachStopCluster NaptanOnstreetBusCoachStopPair NaptanPrivateBusCoachTram NaptanPublicBusCoachTram]

  def postcode_bus_info(postcode)
    bus_stops = get_two_nearby_bus_stops(postcode)
    bus_stops.each do |stop|
      puts("#{stop["name"]} (#{stop["distance"].to_s} metres away)")
      stop["stops_with_direction"].each do |stop_with_direction|
        puts("=== Direction: #{stop_with_direction["naptanId"][-1]}")
        bus_arrivals = get_bus_arrivals(stop_with_direction["naptanId"])
      end
    end
  end
  def get_bus_arrivals(stop)
    url = "https://api.tfl.gov.uk/StopPoint/#{stop}/Arrivals"
    response = URI.open(url).read
    json = JSON.parse(response)
    json.sort_by!{|bus| bus["timeToStation"]}
    json = json.slice(0,5)
    json.each { |bus|
      puts("====== Number #{bus["lineId"].to_s} to #{bus["destinationName"].to_s} (#{(bus["timeToStation"].to_i/60).to_s} minutes away)")
    }
  end
  def get_two_nearby_bus_stops(postcode)
    coords = get_coordinates_of_postcode(postcode)
    bus_stops = get_two_nearby_bus_stops_from_coord(coords)
    return bus_stops
  end
  private
  def get_coordinates_of_postcode(postcode)
    url = "https://api.postcodes.io/postcodes/#{postcode}"
    response = URI.open(url).read
    json = JSON.parse(response)
    return Coordinates.new(json['result']['latitude'],json['result']['longitude'])
  end
  def get_two_nearby_bus_stops_from_coord(coordinates)
    metre_radius = 500
    url = "https://api.tfl.gov.uk/StopPoint/?lat=#{coordinates.latitude}&lon=#{coordinates.longitude}&stopTypes=#{@@stop_types.join(",")}&radius=#{metre_radius}&modes=bus"
    response = URI.open(url).read
    json = JSON.parse(response)
    output = json["stopPoints"].sort_by{|element| element["distance"]}
    output = output.map{|element| {"distance" =>element["distance"].round.to_i,"name" => element["children"][0]["commonName"], "stops_with_direction" => element["children"]}}
    output = output.slice(0,2)
    return output
  end
end

api = APIHandler.new()
# api.get_bus_arrivals("490008660N")
api.postcode_bus_info("NW51TL")

#monday: check if greenwood centre having no results is correct

#Make it so that your console application takes a bus stop code as an input,
# and prints out the next 5 buses at that stop, listing each bus’s line number, destination, and minutes until arrival.
#
# 5 buses
# line number: lineId
# destination: destinationName
# minutes until arrival: timeToStation (seconds)
# #https://api.tfl.gov.uk/StopPoint/{id}/Arrivals
# #490008660N