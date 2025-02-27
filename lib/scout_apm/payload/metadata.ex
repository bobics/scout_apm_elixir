defmodule ScoutApm.Payload.Metadata do
  defstruct [
    :app_root,
    :unique_id,
    :payload_version,
    :agent_version,
    :agent_time,
    :agent_pid,
    :platform
  ]

  def new(timestamp) do
    app_root =
      case File.cwd() do
        {:ok, path} ->
          path

        {:error, _reason} ->
          nil
      end

    %__MODULE__{
      app_root: app_root,
      unique_id: ScoutApm.Utils.random_string(20),
      payload_version: 1,
      agent_version: ScoutApm.Utils.agent_version(),
      agent_time: timestamp |> DateTime.from_naive!("Etc/UTC") |> DateTime.to_iso8601(),
      agent_pid: System.get_pid() |> String.to_integer(),
      platform: "elixir"
    }
  end
end
