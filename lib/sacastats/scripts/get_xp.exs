import PS2.API.QueryBuilder
alias PS2.API.Query

to_int_or_float = fn string ->
  case Integer.parse(string) do
    {_num, "." <> _rest} -> String.to_float(string)
    {num, _rest} -> num
    :error -> 0
  end
end

{:ok, %PS2.API.QueryResult{data: xp_list}} =
  PS2.API.query(Query.new(collection: "experience") |> limit(5000), "example")

new_xp_map =
  for xp_map <- xp_list, into: %{} do
    xp_map
    |> Map.update("xp", 0, to_int_or_float)
    |> Map.pop!("experience_id")
  end
  |> Jason.encode!(pretty: true)

File.write("./lib/sacastats/static_data/xp.json", new_xp_map)
