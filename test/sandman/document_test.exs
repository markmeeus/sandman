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
    {:ok, doc_pid} = Document.start_link(doc_id, doc_path)
    {:ok, %{doc_pid: doc_pid}}
  end

  test "runs a block", %{doc_id: doc_id, doc_pid: doc_pid} do
    Document.run_block(doc_pid, "b805b47a-fb65-4751-981e-32e260d7c513")
    Process.sleep(100)
    assert_receive({:log, %{text: "hello test", type: "log"}})
  end

  test "it runs block 2 with state from block 1", %{doc_id: doc_id, doc_pid: doc_pid} do
    Document.run_block(doc_pid, "b805b47a-fb65-4751-981e-32e260d7c513")
    Document.run_block(doc_pid, "b805b47a-fb65-4751-981e-32e260d7c514")
    Process.sleep(100)
    assert_receive({:log, %{text: "hello from first block", type: "log"}})
  end

  test "it logs an error when the previous block has no state", %{doc_id: doc_id, doc_pid: doc_pid} do
    Document.run_block(doc_pid, "b805b47a-fb65-4751-981e-32e260d7c514")
    Process.sleep(1000)
    assert_receive({:log, %{text: "This block cannot be run right now. Did you run the previous block?", type: "log"}})
  end
end
