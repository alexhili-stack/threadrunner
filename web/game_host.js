"use strict";
(()=>{
  const canvas=document.getElementById("canvas"),state=document.getElementById("game-state");
  const allowed=new Set(["move_left","move_right","jump","restart","pause","thread_stitch","thread_grapple","thread_rewind"]);
  let input=null,pause=null;
  const localQA=["localhost","127.0.0.1"].includes(location.hostname)&&new URLSearchParams(location.search).get("qa")==="1";
  function notify(type,data={}){if(parent!==window)parent.postMessage({type,...data},location.origin);}
  window.ThreadrunnerHost={
    connectInput(inputFunction,pauseFunction){input=inputFunction;pause=pauseFunction;},
    setStatus(raw){const status=JSON.parse(raw);state.textContent=raw;for(const [key,value]of Object.entries(status))state.dataset[key]=String(value);notify("threadrunner-status",{status});},
    verificationComplete(raw){const report=JSON.parse(raw);document.getElementById("qa-report").textContent=raw;document.getElementById("qa-report").dataset.pass=String(report.pass);notify("threadrunner-qa",{report});}
  };
  addEventListener("message",event=>{
    if(event.origin!==location.origin||event.source!==parent||!event.data)return;
    const message=event.data;
    if(message.type==="threadrunner-input"&&input&&allowed.has(message.action)&&typeof message.pressed==="boolean")input(message.action,message.pressed);
    if(message.type==="threadrunner-pause"&&pause&&!localQA)pause();
    if(message.type==="threadrunner-focus")canvas.focus({preventScroll:true});
  });
  document.addEventListener("visibilitychange",()=>{if(document.hidden&&pause&&!localQA)pause();});
  addEventListener("blur",()=>setTimeout(()=>{if(localQA)return;try{if((document.hidden||!parent.document.hasFocus())&&pause)pause();}catch{if(pause)pause();}},0));
  canvas.addEventListener("contextmenu",event=>event.preventDefault());
  const config={...window.threadrunnerEngineConfig,canvas,canvasResizePolicy:2,focusCanvas:true,
    onProgress(current,total){notify("threadrunner-progress",{current,total});},
    onPrintError(...args){const text=args.join(" ");console.error(text);state.dataset.lastError=text;},
    onExit(code){state.dataset.exitCode=String(code);}
  };
  const engine=new Engine(config);
  async function start(){
    if(Engine.isWebGLAvailable&&!Engine.isWebGLAvailable(2))throw new Error("WebGL 2 is unavailable. Try a current browser with hardware acceleration enabled.");
    if(localQA){await engine.preloadFile("../qa-fixtures.json","/qa-inputs.json");config.args=["--","--save-dir=/tmp/threadrunner-qa","--qa-fixture=/qa-inputs.json","--qa-output=/qa-output.json"];}
    await engine.startGame(config);canvas.focus({preventScroll:true});
  }
  start().catch(error=>{state.dataset.error=String(error);notify("threadrunner-error",{message:String(error.message||error)});});
})();
