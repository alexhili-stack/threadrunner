"use strict";
const frame=document.getElementById("game"),boot=document.getElementById("boot"),play=document.getElementById("play"),loading=document.getElementById("loading"),progress=document.getElementById("progress"),status=document.getElementById("status"),state=document.getElementById("game-state"),touch=document.getElementById("touch"),touchToggle=document.getElementById("touch-toggle"),pause=document.getElementById("pause");
let started=false,ready=false,lastPage="",lastRoom=0;
const held=new Map();
function send(action,pressed){if(ready)frame.contentWindow.postMessage({type:"threadrunner-input",action,pressed},location.origin);}
function releaseAll(){for(const [button,action]of held){button.classList.remove("held");send(action,false);}held.clear();}
function showTouch(value){touch.hidden=!value;touchToggle.setAttribute("aria-pressed",String(value));if(!value)releaseAll();}
showTouch(matchMedia("(pointer:coarse)").matches||innerWidth<720);
touchToggle.addEventListener("click",()=>showTouch(touch.hidden));
for(const button of touch.querySelectorAll("[data-action]")){
  button.disabled=true;
  button.addEventListener("pointerdown",event=>{event.preventDefault();if(button.disabled)return;button.setPointerCapture(event.pointerId);held.set(button,button.dataset.action);button.classList.add("held");send(button.dataset.action,true);});
  const release=event=>{event.preventDefault();if(held.has(button)){send(held.get(button),false);held.delete(button);}button.classList.remove("held");};
  button.addEventListener("pointerup",release);button.addEventListener("pointercancel",release);button.addEventListener("lostpointercapture",release);
  button.addEventListener("contextmenu",event=>event.preventDefault());
}
play.addEventListener("click",()=>{
  if(started){location.reload();return;}
  started=true;play.disabled=true;play.textContent="Loading Threadrunner…";loading.textContent="Preparing your thread…";progress.hidden=false;
  const query=new URLSearchParams(location.search);const localQA=["localhost","127.0.0.1"].includes(location.hostname)&&query.get("qa")==="1";
  frame.src="game/index.html"+(localQA?"?qa=1":"");
});
pause.addEventListener("click",()=>{releaseAll();send("pause",true);setTimeout(()=>send("pause",false),60);});
document.getElementById("fullscreen").addEventListener("click",async()=>{
  try{if(document.fullscreenElement)await document.exitFullscreen();else await document.getElementById("player").requestFullscreen();}
  catch{status.textContent="Fullscreen is unavailable here. You can still play in this window.";}
});
addEventListener("message",event=>{
  if(event.origin!==location.origin||event.source!==frame.contentWindow||!event.data)return;
  const message=event.data;
  if(message.type==="threadrunner-progress"){
    if(message.total>0){progress.value=Math.min(100,message.current/message.total*100);loading.textContent=`Loading the game · ${Math.round(progress.value)}%`;}
    else{progress.removeAttribute("value");loading.textContent="Loading the game…";}
  }
  if(message.type==="threadrunner-error"){
    play.disabled=false;play.textContent="Try again";loading.textContent=message.message||"The game could not start. Try a browser with WebGL 2 enabled.";progress.hidden=true;state.dataset.error=loading.textContent;
  }
  if(message.type==="threadrunner-status"){
    ready=true;boot.hidden=true;progress.hidden=true;
    const data=message.status;state.textContent=JSON.stringify(data);for(const [key,value]of Object.entries(data))state.dataset[key]=String(value);
    const playing=data.page==="game";pause.disabled=!playing&&data.page!=="pause";pause.textContent=data.page==="pause"?"Resume":"Pause";
    for(const button of touch.querySelectorAll("button"))button.disabled=!playing;
    if(!playing)releaseAll();
    if(data.page!==lastPage||data.room!==lastRoom){status.textContent=playing?`Room ${data.room} · ${data.name}`:data.page==="pause"?"Paused. Your thread is waiting.":data.page==="complete"?"Signal delivered. Choose your next room.":data.page==="menu"?"Choose Thread lessons to learn stitching, swinging and rewind.":"Choose an option in the game.";lastPage=data.page;lastRoom=data.room;}
    if(!data.persistent)document.getElementById("save-help").textContent="Browser storage is unavailable, so progress will last for this session only.";
  }
  if(message.type==="threadrunner-qa"){
    const report=document.getElementById("qa-report");report.textContent=JSON.stringify(message.report);report.dataset.pass=String(message.report.pass);state.dataset.qaComplete="true";
  }
});
function pauseIfAway(){if(document.hidden||!document.hasFocus()){releaseAll();frame.contentWindow?.postMessage({type:"threadrunner-pause"},location.origin);}}
document.addEventListener("visibilitychange",pauseIfAway);addEventListener("blur",()=>setTimeout(pauseIfAway,0));
