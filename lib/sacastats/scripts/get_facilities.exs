oshur_facilities = """
Oshur Northern Flotilla (facility ID 400370)
Eagle Outpost (facility ID 400364)
Fort Arceo (facility ID 400363)
Palaso Supply Depot (facility ID 400362)
Seapost J5 (facility ID 400390)
Wellerman Watch (facility ID 400361)
Sibo Interlink (facility ID 400360)
Terran Genetics Inc (facility ID 400359)
Viridian East Terrace (facility ID 400357)
South Viridian Beachhead (facility ID 400358)
Seapost K10 (facility ID 400391)
Emerald Arboretum (facility ID 400368)
Remnant Cove (facility ID 400356)
Emerald Research Co (facility ID 400355)
Southpeak Meadows (facility ID 400354)
Astira Solar Station (facility ID 400353)
Solstice Pass (facility ID 400405)
Dekat Interlink (facility ID 400352)
High Ridge Security (facility ID 400351)
K&H Tech Station (facility ID 400350)
Oshur Southwest Flotilla (facility ID 400369)
Hunter's Ravine (facility ID 400349)
Tannae Power (facility ID 400348)
Veridad Pass (facility ID 400404)
Sage R&D Labs (facility ID 400347)
Nascent Shipping and Storage (facility ID 400367)
Imbanon Interlink (facility ID 400366)
Meridian Listening Post (facility ID 400365)
Hopeswell Beachhead (facility ID 400343)
Anat Interlink (facility ID 400345)
Gildad Cliffs (facility ID 400346)
Lamplight Security (facility ID 400342)
Wavecrest Beachhead (facility ID 400344)
Bago Trident (facility ID 400373)
Sirinan Trident (facility ID 400372)
Anlabban Trident (facility ID 400374)
Ligalai Station (facility ID 400334)
Binusilan Interlink (facility ID 400333)
Outpost Kalis (facility ID 400335)
Seaside Bluffs (facility ID 400336)
Centri Import Hub (facility ID 400332)
Wakerift Beachhead (facility ID 400407)
Astira Hydroelectric (facility ID 400330)
Mirror Bay Watchtower (facility ID 400329)
Pommel Gardens (facility ID 400331)
Mirror Bay Checkpoint (facility ID 400340)
Mirror Bay Watchtower (facility ID 400329)
Viridian Genetics Lab (facility ID 400337)
Viridian Decontamination (facility ID 400338)
Centri Mining Operation (facility ID 400339)
Oshur Southeast Flotilla (facility ID 400371)
Seapost K12 (facility ID 400392)
Pilay Interlink (facility ID 400341)
"""

facility_map =
  for facility <- String.split(oshur_facilities, "\n", trim: true), into: %{} do
    [facility_name, facility_id_str] = String.split(facility, [" (facility ID ", ")"], trim: true)
    facility_id = String.to_integer(facility_id_str)

    {facility_id,
     %{"facility_name" => facility_name, "facility_id" => facility_id, "zone_id" => 344}}
  end

res =
  HTTPoison.get!(
    "https://raw.githubusercontent.com/cooltrain7/Planetside-2-API-Tracker/master/Census/map_region.json"
  )

res_map = Jason.decode!(res.body)

facility_map =
  for facility <- res_map["map_region_list"], into: facility_map do
    {facility["facility_id"],
     Map.new(facility, fn {field_name, value} ->
       {field_name, SacaStats.Utils.maybe_to_int(value)}
     end)}
  end

File.write(
  "./lib/sacastats/static_data/facilities.json",
  Jason.encode!(facility_map, pretty: true)
)
