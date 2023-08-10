defmodule Sandman.FileAccess do
  def select_file(mode) do
    :wx.set_env(Desktop.Env.wx_env())

    file_dialog = case mode do
      :open -> :wxFileDialog.new(:wx.null)#, [wildCard: "*.lua"]) => laat niet toe iets anders te kiezen...
      :new -> :wxFileDialog.new(:wx.null, [style: 2, defaultFile: "new_script.md"])
    end
     #[style: 2]) # 2 is wxFD_SAVE ....

    :wxFileDialog.showModal(file_dialog)
    :filename.join(
      :wxFileDialog.getDirectory(file_dialog),
      :wxFileDialog.getFilename(file_dialog)
    )
    |> case do
      [] -> nil
      file_name ->
        result = to_string(file_name)
        if(mode == :new) do
          File.write(result, Sandman.NewFileTemplate.contents)
        end
        result
    end
  end
end
