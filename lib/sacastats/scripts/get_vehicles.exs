res =
  HTTPoison.get!(
    "https://raw.githubusercontent.com/cooltrain7/Planetside-2-API-Tracker/master/Census/vehicle.json"
  )

res_map = Jason.decode!(res.body)

cost_map = File.read!("./lib/sacastats/static_data/vehicle_cost_map.json") |> Jason.decode!()

vehicle_map =
  for vehicle <- res_map["vehicle_list"], into: %{} do
    cost = cost_map[vehicle["vehicle_id"]] || 0

    {vehicle["vehicle_id"],
     %{
       "name" => vehicle["name"]["en"],
       "description" => vehicle["description"]["en"],
       "cost" => cost,
       "currency_id" => vehicle["cost_resource_id"],
       "image_path" => vehicle["image_path"],
       "type_id" => vehicle["type_id"]
     }}
  end

File.write("./lib/sacastats/static_data/vehicles.json", Jason.encode!(vehicle_map, pretty: true))
