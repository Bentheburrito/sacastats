import Config

if Config.config_env() == :dev do
  DotenvParser.load_file(".env")
end

config :planetside_api, service_id: System.get_env("SERVICE_ID")

config :caidata_api, :data_shortname, "data2@" <> (:inet.gethostname |> elem(1) |> List.to_string()) |> String.to_atom()
