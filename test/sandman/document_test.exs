defmodule Sandman.DocumentTest do

  use ExUnit.Case
  alias Sandman.Document
  alias Phoenix.PubSub

  setup_all do
    doc_id = UUID.uuid4()
    doc_path = Path.join([__DIR__, "fixtures", "test_doc.lua"])

    {:ok, %{doc_id: doc_id, doc_path: doc_path}}
  end
  setup %{doc_id: doc_id, doc_path: doc_path} do
    PubSub.subscribe(Sandman.PubSub, "document:#{doc_id}")
    {:ok, doc_pid} = Document.start_link(doc_id, doc_path, & to_string(&1))
    {:ok, %{doc_pid: doc_pid}}
  end

  test "runs a block", %{doc_pid: doc_pid} do
    Document.run_block(doc_pid, "0")
    Process.sleep(100)
    assert_receive({:log, %{text: "hello test", type: "log"}})
  end

  test "it runs block 2 with state from block 1", %{doc_pid: doc_pid} do
    Document.run_block(doc_pid, "0")
    Document.run_block(doc_pid, "1")
    Process.sleep(100)
    assert_receive({:log, %{text: "hello from first block", type: "log"}})
  end

  test "it logs an error when the previous block has no state", %{doc_pid: doc_pid} do
    Document.run_block(doc_pid, "1")
    Process.sleep(1000)
    assert_receive({:log, %{text: "This block cannot be run right now. Did you run the previous block?", type: "log"}})
  end

  test "it clears the state for all later blocks when running a previous block",  %{doc_pid: doc_pid} do
    Document.run_block(doc_pid, "0")
    Document.run_block(doc_pid, "1")
    Document.run_block(doc_pid, "2")
    # running first block again, 3d block cannot be run
    Document.run_block(doc_pid, "0")
    Document.run_block(doc_pid, "2")
    Process.sleep(100)
    assert_receive({:log, %{text: "This block cannot be run right now. Did you run the previous block?", type: "log"}})
  end
end
