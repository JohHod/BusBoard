require 'open-uri'
require 'json'

class PagesController < ApplicationController
  def index
    puts("postcode: "+params[:postcode].to_s)
    api = APIHandler.new()
    @bus_data = api.postcode_bus_info(params[:postcode])
  end
  class APIHandler
    Coordinates = Struct.new(:latitude,:longitude)
    Bus_Stop = Struct.new(:name, :id, :distance)
    @@stop_types = %w[NaptanBusCoachStation NaptanBusWayPoint NaptanOnstreetBusCoachStopCluster NaptanOnstreetBusCoachStopPair NaptanPrivateBusCoachTram NaptanPublicBusCoachTram]

    def postcode_bus_info(postcode)
      bus_stops = get_two_nearby_bus_stops(postcode)
      if bus_stops == [] then return [] end
      bus_stops.each do |stop|
        puts("#{stop["common_name"]} (#{stop["distance"].to_s} metres away)")
        stop["stops_with_direction"].each do |stop_with_direction|
          stop_with_direction["bus_arrivals"] = get_bus_arrivals(stop_with_direction["naptan_id"])
        end
      end
      return bus_stops;
    end
    def get_bus_arrivals(stop)
      url = "https://api.tfl.gov.uk/StopPoint/#{stop}/Arrivals"
      puts(url)
      response = URI.open(url).read
      json = JSON.parse(response)
      json.sort_by!{|bus| bus["timeToStation"]}
      json = json.slice(0,5)
      output = json.map{|element| {"line_id"=>element["lineId"].to_s,
                                   "destination_name"=>element["destinationName"].to_s ,
                                   "time_to_station"=>(element["timeToStation"].to_i/60).to_s} }
      puts(output)
      return output
    end
    def get_two_nearby_bus_stops(postcode)
      coords = get_coordinates_of_postcode(postcode)
      if not coords == -1 then
        bus_stops = get_two_nearby_bus_stops_from_coord(coords)
        return bus_stops
      else
        return []
      end
    end
    private
    def get_coordinates_of_postcode(postcode)
      url = "https://api.postcodes.io/postcodes/#{postcode}"
      puts(url)
      begin
        response = URI.open(url).read
      rescue OpenURI::HTTPError => error
        return -1
      end
      json = JSON.parse(response)
      return Coordinates.new(json['result']['latitude'],json['result']['longitude'])
    end
    def get_two_nearby_bus_stops_from_coord(coordinates)
      metre_radius = 500
      url = "https://api.tfl.gov.uk/StopPoint/?lat=#{coordinates.latitude}&lon=#{coordinates.longitude}&stopTypes=#{@@stop_types.join(",")}&radius=#{metre_radius}&modes=bus"
      puts(url)
      response = URI.open(url).read
      json = JSON.parse(response)
      output = json["stopPoints"].sort_by{|element| element["distance"]}
      # output = output.map{|element| {"distance" =>element["distance"].round.to_i,"name" => element["children"][0]["commonName"], "stops_with_direction" => element["children"]}}
      output = output.map{|element| {"distance" =>element["distance"].round.to_i,
                                     "common_name" => element["commonName"],
                                     "stops_with_direction" => element["children"].map{|child| {"naptan_id"=>child["naptanId"],
                                                                                                "compass_point"=>if child["additionalProperties"].length>0 then child["additionalProperties"][0]["value"] else "error" end,
                                                                                                "towards"=>if child["additionalProperties"].length > 1 then child["additionalProperties"][1]["value"] else "error" end,
                                                                                                "bus_arrivals"=>[]}}}}
      output = output.slice(0,10)
      return output

      # commonName
      # distance
      # stops_with_direction (children)
      # # naptanId
      # # direction (end of naptanId)
      # # stopLetter
      # # arrivals
      # # # lineId
      # # # destinationName
      # # # timeToStation


    end
  end
end
