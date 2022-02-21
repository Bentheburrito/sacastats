res =
  HTTPoison.get!(
    "https://raw.githubusercontent.com/cooltrain7/Planetside-2-API-Tracker/master/Weapons/sanction-list.csv"
  )

[_headers | lines] = String.split(res.body, "\n")

weapon_map =
  for line <- lines, into: %{} do
    [item_id, category, is_vehicle_weapon, item_name, faction_id, sanction] =
      String.split(line, ",")

    {item_id,
     %{
       "category" => category,
       "vehicle_weapon?" => is_vehicle_weapon == "1",
       "name" => item_name,
       "faction_id" => (String.length(faction_id) > 0 && String.to_integer(faction_id)) || nil,
       "sanction" => sanction
     }}
  end

File.write("./lib/sacastats/static_data/weapons.json", Jason.encode!(weapon_map, pretty: true))
