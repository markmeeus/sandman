defmodule Sandman.DocumentTest do

  use ExUnit.Case
  alias Sandman.Document
  alias Phoenix.PubSub

  defp start_doc(fixture) do
    doc_id = UUID.uuid4()
    doc_path = Path.join([__DIR__, "fixtures", fixture])

    PubSub.subscribe(Sandman.PubSub, "document:#{doc_id}")
    {:ok, doc_pid} = Document.start_link(doc_id, doc_path, & to_string(&1))
    {:ok, %{doc_pid: doc_pid}}
  end

  defp setup_basic_doc(_), do: start_doc("test_doc.md")
  defp setup_json(_), do: start_doc("json_test.md")

  describe "run blocks in correct order" do
    setup [:setup_basic_doc]
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

  describe "json support" do
    setup [:setup_json]
    test "should decode and encode correctly", %{doc_pid: doc_pid} do
      Document.run_block(doc_pid, "0")
      Process.sleep(100)


      assert_receive({:log, %{text: "is it json? Array has 3 elements.", type: "log"}})
      assert_receive({:log, %{text: "{\"anArray\":[1,2,3],\"this\":\"json\"}", type: "log"}})
    end
  end
end
