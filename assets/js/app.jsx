//MONACO: => https://szajbus.dev/elixir/2023/05/15/how-to-use-monaco-editor-with-phoenix-live-view-and-esbuild.html
// I Didn't rename the css part

// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import React from "react";
import { createRoot } from 'react-dom/client';
import Document from './components/document';
import topbar from "../vendor/topbar"

import hotkeys from 'hotkeys-js';

import HomeHook from './hooks/home';
import MonacoHook from "./hooks/monaco";
import DocumentHook from "./hooks/document";
import MaintainDimensions from "./hooks/maintainDimensions";
import TitleForm from "./hooks/titleForm";

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {
  params: {_csrf_token: csrfToken},
  hooks: {
		HomeHook,
		MonacoHook,
		DocumentHook,
		MaintainDimensions,
		TitleForm
  }
})

// disable backspace navigation
function isTextInput(element) {
  var tagName = element.tagName.toLowerCase();

	if(tagName === "input") {
		// backspace allowed on input type="text"
		var typeAttr = element.getAttribute('type').toLowerCase();
		return typeAttr === 'text';
	}

	if(tagName === "textarea") return true;
}

window.onkeydown = function(e) {
	if (e.keyCode == 8 && !isTextInput(e.target)) e.preventDefault();
}


// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket


self.MonacoEnvironment = {
	globalAPI: true,
	getWorkerUrl(_workerId, label) {
		switch (label) {
			case "css":
			case "less":
			case "scss":
				return "/assets/monaco-editor/language/css/css.worker.js";
			case "html":
			case "handlebars":
			case "razor":
				return "/assets/monaco-editor/language/html/html.worker.js";
			case "json":
				return "/assets/monaco-editor/language/json/json.worker.js";
			case "javascript":
			case "typescript":
				return "/assets/monaco-editor/language/typescript/ts.worker.js";
			default:
				return "/assets/monaco-editor/editor/editor.worker.js";
		}
	},
};
