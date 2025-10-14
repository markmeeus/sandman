defmodule Sandman.KeepAliveManager do
  @moduledoc """
  GenServer that manages the keepalive functionality for the Phoenix application.

  If no keepalive request is received for 30 seconds, the entire BEAM process will exit.
  Uses GenServer's built-in timeout functionality for reliable timeout handling.
  """

  use GenServer
  require Logger

  @timeout_ms 30_000  # 30 seconds

  ## Client API

  @doc """
  Starts the KeepAliveManager.
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Sends a keepalive signal to the manager, resetting the timeout.
  """
  def keepalive do
    GenServer.cast(__MODULE__, :keepalive)
  end

  @doc """
  Gets the current status of the keepalive manager.
  """
  def status do
    GenServer.call(__MODULE__, :status)
  end

  ## Server Callbacks

  @impl true
  def init(_opts) do
    Logger.info("KeepAliveManager started - will exit if no keepalive received for #{@timeout_ms}ms")

    state = %{
      last_keepalive: System.monotonic_time(),
      keepalive_count: 0
    }

    # Use GenServer's built-in timeout functionality
    {:ok, state, @timeout_ms}
  end

  @impl true
  def handle_cast(:keepalive, state) do
    Logger.debug("KeepAliveManager received keepalive signal (count: #{state.keepalive_count + 1})")

    new_state = %{
      last_keepalive: System.monotonic_time(),
      keepalive_count: state.keepalive_count + 1
    }

    # Reset the timeout by returning it in the reply
    {:noreply, new_state, @timeout_ms}
  end

  @impl true
  def handle_call(:status, _from, state) do
    time_since_last = System.monotonic_time() - state.last_keepalive
    time_since_last_ms = System.convert_time_unit(time_since_last, :native, :millisecond)

    status = %{
      last_keepalive: state.last_keepalive,
      time_since_last_ms: time_since_last_ms,
      timeout_ms: @timeout_ms,
      remaining_ms: max(0, @timeout_ms - time_since_last_ms),
      keepalive_count: state.keepalive_count
    }

    {:reply, status, state, @timeout_ms}
  end

  @impl true
  def handle_info(:timeout, state) do
    Logger.warning("KeepAliveManager timeout reached - no keepalive received for #{@timeout_ms}ms")
    Logger.warning("Total keepalive signals received: #{state.keepalive_count}")
    Logger.warning("Exiting BEAM process...")

    Logger.flush()
    Process.sleep(1000) # allow logger to properly flush
    # Exit the entire BEAM process
    System.halt(0)

    {:noreply, state}
  end
end
