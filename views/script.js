var socket = {};
var keys = [];
var connected = false;
for(var i = 0; i < 61; i++){
	keys.push(false);
}
console.log(keys);
socket = new WebSocket("ws://" + window.location.href.substring(7) + "ws");
socket.onopen = function(){
	connected = true;
	drawPiano();
}
socket.onclose = function(){
	connected = false;
	drawPiano();
}
socket.onmessage = function(msg){
	var data = JSON.parse(msg.data);
	var key = data.key - 36;
	keys[key] = data.state;
	drawPiano();
}
function drawPiano(){
	var ctx = document.getElementById("piano").getContext("2d");
	ctx.strokeStyle = "#000000";
	for(var x = 0; x < 36; x++){
		if(keys[x * 2 - 2 * Math.floor(x / 7) - Math.floor(x % 7 / 3) + Math.floor(x % 7 / 6)] == true) ctx.fillStyle = "#5998ff";
		else ctx.fillStyle = "#FFFFFF";
		ctx.fillRect(x * 32, 0, 32, 192);
		ctx.strokeRect(x * 32, 0, 32, 192);
	}
	for(var x = 0; x < 35; x++){
		if(keys[1 + x * 2 - 2 * Math.floor(x / 7) - Math.floor(x % 7 / 3)] == true) ctx.fillStyle = "#5998ff";
		else ctx.fillStyle = "#000000";
		if(x % 7 != 2 && x % 7 != 6){
			ctx.fillRect(x * 32 + 24, 0, 16, 112);
			ctx.strokeRect(x * 32 + 24, 0, 16, 112);
		}
	}
	if(!connected){
		ctx.fillStyle = "rgba(66, 11, 11, 0.5)";
		ctx.fillRect(0, 0, 1152, 192);
	}
}
drawPiano();