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

  def select_file do
    :wx.set_env(Desktop.Env.wx_env())
    file_dialog = GenServer.whereis(MainApp)
    |> Desktop.Window.webview()
    |> :wxFileDialog.new() #[style: 2]) # 2 is wxFD_SAVE ....

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
