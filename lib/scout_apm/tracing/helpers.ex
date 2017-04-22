defmodule ScoutApm.Tracing.Helpers do
  @moduledoc """
  Functions to time the execution of code.

  __IMPORTANT__: We limit the arity of `type` to 10 per-reporting period. These are displayed in
  charts throughput the UI. These should not be generated dynamically and are designed to be higher-level
  categories (ie Postgres, Redis, HTTP, etc).
  """
  require Logger

  @doc """
  Instruments the given `function`, labeling it with `type` and `name` within Scout.

  Within a trace in the Scout UI, the `function` will appear as `type/name` ie "Images/format_avatar".

  ## Example Usage

      defmodule PhoenixApp.PageController do
        use PhoenixApp.Web, :controller
        import ScoutApm.Tracing.Helpers

        def index(conn, _params) do
          instrument("Timer", "sleep", fn ->
            :timer.sleep(3000)
          end)
          render conn, "index.html", layout: {PhoenixApp.LayoutView, "index.html"}
        end
  """
  def instrument(type, name, function) when is_function(function) do
    ScoutApm.TrackedRequest.start_layer(type,name)
    result = function.()
    ScoutApm.TrackedRequest.stop_layer
    result
  end

  @doc """
  Adds an instrumention entry of duration `value` with `units`, labeling it with `type` and `name` within Scout.

  ## Units

  Can be be one of `:microseconds | :milliseconds | :seconds`. These come from `t:ScoutApm.Internal.Duration.unit/0`.

  ## Example Usage

      instrument("HTTP","get",300,:milliseconds)

  ## The duration must have actually occured

    This function expects that the ` ScoutApm.Internal.Duration` generated by `value` and `units` actually occurs in
    the transaction. The total time of the transaction IS NOT adjusted.

    This naturally occurs when taking the output of Ecto log entries.
  """
  def instrument(type, name, value, units) when is_number(value) do
    duration = ScoutApm.Internal.Duration.new(value, units)
    ScoutApm.TrackedRequest.track_layer(type, name, duration)
  end
end
