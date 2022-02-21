# Get weapon info with sanctions
res =
  HTTPoison.get!(
    "https://raw.githubusercontent.com/cooltrain7/Planetside-2-API-Tracker/master/Weapons/sanction-list.csv"
  )

[_headers | lines] = String.split(res.body, "\n")

# Get weapon image info
import PS2.API.QueryBuilder
alias PS2.API.{Query, Tree, QueryResult}

default_image_info = %{"image_id" => 3, "image_path" => "/files/ps2/images/static/3.png"}

weapon_image_infos =
  lines
  |> Stream.map(&(&1 |> String.split(",") |> List.first()))
  |> Stream.chunk_every(800)
  |> Stream.map(fn item_ids ->
    {:ok, %QueryResult{data: item_images}} =
      Query.new(collection: "item")
      |> term("item_id", Enum.join(item_ids, ","))
      |> limit(9000)
      |> show(["item_id", "image_id", "image_path"])
      |> tree(Tree.new(field: "item_id"))
      |> PS2.API.query_one(SacaStats.sid())

    item_images
  end)
  |> Enum.reduce(&Map.merge(&1, &2))
  |> Stream.filter(fn {_key, value} -> value != "-" end)
  |> Stream.map(fn {item_id, images} ->
    IO.inspect(images)
    {item_id, Map.update!(images, "image_id", &SacaStats.Utils.StaticData.maybe_to_int(&1))}
  end)
  |> Enum.into(%{})

weapon_map =
  for line <- lines, into: %{} do
    [item_id, category, is_vehicle_weapon, item_name, faction_id, sanction] =
      String.split(line, ",")

    # Replace excessive quotation
    item_name =
      item_name
      # completely remove single "'s
      |> String.replace(~r/(.?)"(.?)/, "\\1\\2", global: true)
      # condense consecutive "'s to one "
      |> String.replace(~r/(?:"){2,}/, "\"", global: true)

    weapon_info = %{
      "category" => category,
      "vehicle_weapon?" => is_vehicle_weapon == "1",
      "name" => item_name,
      "faction_id" => (String.length(faction_id) > 0 && String.to_integer(faction_id)) || nil,
      "sanction" => sanction
    }

    image_info = Map.get(weapon_image_infos, item_id, default_image_info)

    full_weapon_info = Map.merge(weapon_info, image_info)

    {item_id, full_weapon_info}
  end

File.write("./lib/sacastats/static_data/weapons.json", Jason.encode!(weapon_map, pretty: true))
