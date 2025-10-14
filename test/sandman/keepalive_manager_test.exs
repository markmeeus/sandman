defmodule Sandman.KeepAliveManagerTest do
  use ExUnit.Case, async: false
  alias Sandman.KeepAliveManager

  test "keepalive manager responds to keepalive signals" do
    # The manager should already be running from the application supervision tree
    # Just test that it responds to keepalive signals

    # Send a keepalive signal
    KeepAliveManager.keepalive()

    # Check status
    status = KeepAliveManager.status()
    assert status.timeout_ms == 30_000
    assert status.remaining_ms > 0
    assert status.remaining_ms <= 30_000
    assert status.keepalive_count >= 1
  end

  test "keepalive manager resets timeout on keepalive signal" do
    # Get initial status
    initial_status = KeepAliveManager.status()
    initial_count = initial_status.keepalive_count

    # Wait a bit
    Process.sleep(100)

    # Send keepalive signal
    KeepAliveManager.keepalive()

    # Check that timeout was reset and count increased
    new_status = KeepAliveManager.status()
    assert new_status.remaining_ms >= initial_status.remaining_ms
    assert new_status.remaining_ms <= 30_000
    assert new_status.remaining_ms > 29_000  # Should be close to 30 seconds after reset
    assert new_status.keepalive_count == initial_count + 1
  end

  test "keepalive manager tracks multiple keepalive signals" do
    # Send multiple keepalive signals
    KeepAliveManager.keepalive()
    KeepAliveManager.keepalive()
    KeepAliveManager.keepalive()

    # Check that count increased
    status = KeepAliveManager.status()
    assert status.keepalive_count >= 3
  end
end
