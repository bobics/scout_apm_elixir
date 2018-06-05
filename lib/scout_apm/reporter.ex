defmodule ScoutApm.Reporter do
  @success_http_codes 200..299
  @error_http_codes 400..499

  def report(encoded_payload) do
    monitor = ScoutApm.Config.find(:monitor)
    key = ScoutApm.Config.find(:key)

    case {monitor, key} do
      {nil, nil} ->
        ScoutApm.Logger.log(:debug, "Skipping Reporting, both monitor and key settings are missing")
        :ok

      {true, nil} ->
        ScoutApm.Logger.log(:debug, "Skipping Reporting, key is nil")
        :ok

      {true, ""} ->
        ScoutApm.Logger.log(:debug, "Skipping Reporting, key is empty")
        :ok

      {nil, _} ->
        ScoutApm.Logger.log(:debug, "Skipping Reporting, monitor is nil")
        :ok

      {false, _} ->
        ScoutApm.Logger.log(:debug, "Skipping Reporting, monitor is false")
        :ok

      _ ->
        post(encoded_payload)
    end
  end

  def post(encoded_payload) do
    host = ScoutApm.Config.find(:host)
    name = ScoutApm.Config.find(:name)
    key = ScoutApm.Config.find(:key)

    gzipped_payload = :zlib.gzip(encoded_payload)
    method = :post

    query = URI.encode_query(%{"key" => key, "name" => name})
    url = <<"#{host}/apps/checkin.scout?#{query}">>

    options = []

    header_list = headers()

    ScoutApm.Logger.log(:debug, "Reporting ScoutAPM Payload to #{url}")
    ScoutApm.Logger.log(:debug, "Payload Size. JSON: #{inspect :erlang.iolist_size(encoded_payload)}, Gzipped: #{inspect :erlang.iolist_size(gzipped_payload)}")
    # ScoutApm.Logger.log(:debug, "JSON Payload: #{inspect encoded_payload}")
    # ScoutApm.Logger.log(:debug, "Headers: #{inspect header_list}")

    case :hackney.request(method, url, header_list , gzipped_payload, options) do

      {:ok, status_code, resp_headers, _client_ref} when status_code in @error_http_codes ->
        ScoutApm.Logger.log(:info, "Reporting ScoutAPM Payload Failed with #{status_code}. Response Headers: #{inspect resp_headers}")

      {:ok, status_code, _resp_headers, _client_ref} when status_code in @success_http_codes ->
        ScoutApm.Logger.log(:debug, "Reporting ScoutAPM Payload Succeeded. Status: #{inspect status_code}")

      {:ok, status_code, _resp_headers, _client_ref} ->
        ScoutApm.Logger.log(:info, "Reporting ScoutAPM Payload Unexpected Status: #{inspect status_code}")

      {:error, ereason} ->
        ScoutApm.Logger.log(:info, "Reporting ScoutAPM Payload Failed: Hackney Error: #{inspect ereason}")

      r ->
        ScoutApm.Logger.log(:info, "Reporting ScoutAPM Payload Failed: Unknown Hackney Error: #{inspect r}")
    end

    :ok
  end

  def headers do
    [
      {"Agent-Hostname", ScoutApm.Cache.hostname()},
      {"Agent-Version", ScoutApm.Utils.agent_version()},
      {"Content-Type", "application/json"},
      {"Content-Encoding", "gzip"},
    ]
  end

end
