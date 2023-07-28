import JSONFormatter from 'json-formatter-js'
window.showJson = function(){
  const formatter = new JSONFormatter(window.json);

  document.body.appendChild(formatter.render());
}
