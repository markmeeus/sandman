import JSONFormatter from 'json-formatter-js'
window.showJson = function(){
  const formatter = new JSONFormatter(window.json, null, {theme: 'dark'});

  document.body.appendChild(formatter.render());
}
