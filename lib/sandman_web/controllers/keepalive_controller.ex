defmodule SandmanWeb.KeepAliveController do
  @moduledoc """
  Controller that handles keepalive requests to prevent the BEAM process from exiting.
  """

  use SandmanWeb, :controller
  alias Sandman.KeepAliveManager

  @doc """
  Handles GET /keepalive requests.

  This endpoint is called by the macOS frontend every 5 seconds to keep the
  BEAM process alive. If no keepalive is received for 30 seconds, the process exits.
  """
  def keepalive(conn, _params) do
    # Send keepalive signal to the manager
    KeepAliveManager.keepalive()

    # Return a simple success response
    json(conn, %{
      status: "ok",
      message: "keepalive received",
      timestamp: System.system_time(:second)
    })
  end

  @doc """
  Handles GET /keepalive/status requests.

  Returns the current status of the keepalive manager for debugging purposes.
  """
  def status(conn, _params) do
    status = KeepAliveManager.status()

    json(conn, %{
      status: "ok",
      keepalive_info: status
    })
  end
end
