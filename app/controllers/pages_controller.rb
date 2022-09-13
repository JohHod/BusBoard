require 'open-uri'
require 'json'

class PagesController < ApplicationController
  def index
    api = APIHandler.new()
    params[:postcode] = params[:postcode].upcase
    debug = false
    @bus_data = [{"distance"=>91, "common_name"=>"Lady Somerset Road", "stops_with_direction"=>[{"naptan_id"=>"490008660N", "compass_point"=>"N", "towards"=>"Highgate Village Or Parliament Hill Fields", "indicator"=>"GY", "bus_arrivals"=>[{"line_id"=>"214", "destination_name"=>"Highgate Village", "time_to_station"=>"0"}, {"line_id"=>"88", "destination_name"=>"Parliament Hill Fields", "time_to_station"=>"6"}, {"line_id"=>"214", "destination_name"=>"Highgate Village", "time_to_station"=>"12"}, {"line_id"=>"214", "destination_name"=>"Highgate Village", "time_to_station"=>"15"}, {"line_id"=>"214", "destination_name"=>"Highgate Village", "time_to_station"=>"16"}]}, {"naptan_id"=>"490015367S", "compass_point"=>"S", "towards"=>"Camden Town", "indicator"=>"GW", "bus_arrivals"=>[{"line_id"=>"88", "destination_name"=>"Clapham Common", "time_to_station"=>"1"}, {"line_id"=>"214", "destination_name"=>"Moorgate, Finsbury Square", "time_to_station"=>"3"}, {"line_id"=>"88", "destination_name"=>"Clapham Common", "time_to_station"=>"11"}, {"line_id"=>"214", "destination_name"=>"Moorgate, Finsbury Square", "time_to_station"=>"12"}, {"line_id"=>"214", "destination_name"=>"Moorgate, Finsbury Square", "time_to_station"=>"18"}]}]}, {"distance"=>107, "common_name"=>"Greenwood Centre", "stops_with_direction"=>[{"naptan_id"=>"490006943N", "compass_point"=>"N", "towards"=>"Highgate", "indicator"=>"KH", "bus_arrivals"=>[{"line_id"=>"88", "destination_name"=>"Parliament Hill Fields", "time_to_station"=>"7"}, {"line_id"=>"214", "destination_name"=>"Highgate Village", "time_to_station"=>"11"}, {"line_id"=>"214", "destination_name"=>"Highgate Village", "time_to_station"=>"12"}, {"line_id"=>"214", "destination_name"=>"Highgate Village", "time_to_station"=>"15"}, {"line_id"=>"88", "destination_name"=>"Parliament Hill Fields", "time_to_station"=>"22"}]}, {"naptan_id"=>"490008660S", "compass_point"=>"SE", "towards"=>"Camden Town", "indicator"=>"", "bus_arrivals"=>[{"line_id"=>"214", "destination_name"=>"Moorgate, Finsbury Square", "time_to_station"=>"0"}, {"line_id"=>"88", "destination_name"=>"Clapham Common", "time_to_station"=>"1"}, {"line_id"=>"214", "destination_name"=>"Moorgate, Finsbury Square", "time_to_station"=>"4"}, {"line_id"=>"88", "destination_name"=>"Clapham Common", "time_to_station"=>"12"}, {"line_id"=>"214", "destination_name"=>"Moorgate, Finsbury Square", "time_to_station"=>"13"}]}]}, {"distance"=>204, "common_name"=>"Fortess Road", "stops_with_direction"=>[{"naptan_id"=>"490006943E", "compass_point"=>"S", "towards"=>"Camden Town", "indicator"=>"KJ", "bus_arrivals"=>[{"line_id"=>"214", "destination_name"=>"Moorgate, Finsbury Square", "time_to_station"=>"1"}, {"line_id"=>"88", "destination_name"=>"Clapham Common", "time_to_station"=>"3"}, {"line_id"=>"214", "destination_name"=>"Moorgate, Finsbury Square", "time_to_station"=>"5"}, {"line_id"=>"88", "destination_name"=>"Clapham Common", "time_to_station"=>"13"}, {"line_id"=>"214", "destination_name"=>"Moorgate, Finsbury Square", "time_to_station"=>"14"}]}]}]
    if debug == false then
      @bus_data = api.postcode_bus_info(params[:postcode])
    end

    if @bus_data == [] then params[:error] = 1 end
  end
  class APIHandler
    Coordinates = Struct.new(:latitude,:longitude)
    Bus_Stop = Struct.new(:name, :id, :distance)
    @@stop_types = %w[NaptanBusCoachStation NaptanBusWayPoint NaptanOnstreetBusCoachStopCluster NaptanOnstreetBusCoachStopPair NaptanPrivateBusCoachTram NaptanPublicBusCoachTram]

    def postcode_bus_info(postcode)
      bus_stops = get_two_nearby_bus_stops(postcode)
      if bus_stops == [] then return [] end
      bus_stops.each do |stop|
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
      return output
    end
    def get_two_nearby_bus_stops(postcode)
      postcode = ERB::Util::url_encode(postcode)
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
                                                                                                "indicator"=>child["indicator"].length>4?child["indicator"][5..-1]:"",
                                                                                                "bus_arrivals"=>[]}}}}
      output = output.slice(0,3)
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
