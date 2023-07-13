defmodule Sandman.FileAccess do
  # FIle load/save dialog
  # :wx.set_env(Desktop.Env.wx_env())
    # file_dialog = GenServer.whereis(MainApp)
    # |> Desktop.Window.webview()
    # |> :wxFileDialog.new([style: 2]) # 2 is wxFD_SAVE ....

    # :wxFileDialog.showModal(file_dialog)
    # :filename.join(
    #   :wxFileDialog.getDirectory(file_dialog),
    #   :wxFileDialog.getFilename(file_dialog)
    # )
    # |> IO.inspect()

  def select_file(mode) do
    :wx.set_env(Desktop.Env.wx_env())
    webview = MainApp
    |> GenServer.whereis()
    |> Desktop.Window.webview()

    file_dialog = case mode do
      :open -> :wxFileDialog.new(webview) #, [wildCard: "*.lua"]) => laat niet toe iets anders te kiezen...
      :new -> :wxFileDialog.new(webview, [style: 2, defaultFile: "new_script.lua"])
    end
     #[style: 2]) # 2 is wxFD_SAVE ....

    :wxFileDialog.showModal(file_dialog)
    :filename.join(
      :wxFileDialog.getDirectory(file_dialog),
      :wxFileDialog.getFilename(file_dialog)
    )
    |> case do
      [] -> nil
      file_name -> to_string(file_name)
    end
  end
end
