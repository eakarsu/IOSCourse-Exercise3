import { renderAnswer, readableAnswer } from './ai-report.mjs';

const base='http://127.0.0.1:'+document.querySelector('meta[name="api-port"]').content,byId=id=>document.getElementById(id),form=byId('ai-form'),question=byId('question'),status=byId('status'),dialog=byId('detail');
const examples=[
  'Explain the first five positive multiples of 6 to a learner who knows addition but is new to multiplication. Use a numbered worked example, show the repeated-addition connection, identify one common mistake, and finish with one check-for-understanding question.',
  'An illustrative learner says the first five positive multiples of 7 are 7, 14, 20, 28, and 35. Explain where the reasoning went wrong without shaming the learner. Show the correct sequence and arithmetic, then ask one short question to confirm understanding.',
  'Prepare a short illustrative practice plan for finding the first five positive multiples of 9. Start with a worked example, give three progressively harder practice prompts, explain how to check answers using repeated addition, and end with a self-check question.'
];
let token=sessionStorage.getItem('multiples-companion-token')||'',request=null,version=0,reports=[],current=null,selected=null;

async function call(path,options={}){
  const response=await fetch(base+path,{...options,headers:{'Content-Type':'application/json',...(token?{Authorization:'Bearer '+token}:{}),...options.headers}});
  const body=await response.json();if(!response.ok)throw new Error(body.error||'Request failed');return body;
}
function lock(busy){for(const control of form.elements)control.disabled=busy;byId('cancel-request').disabled=false;byId('cancel-request').hidden=!busy;byId('answer').setAttribute('aria-busy',String(busy));}
function stop(){if(!request)return;version++;request.abort();request=null;lock(false);status.textContent='Request canceled. Your question is still here.';}
function show(body){current=body;byId('answer').replaceChildren(renderAnswer(body.content||body.output?.content||''));byId('receipt').textContent='Model: '+body.model+' · Saved report: '+(body.interactionId||body.id);byId('report-actions').hidden=false;}
async function history(){
  const revision=version,body=await call('/api/ai/history');if(revision!==version||!token)return;
  if(!Array.isArray(body.history))throw new Error('Saved reports could not be loaded: unexpected response from the companion API.');
  reports=body.history;const list=byId('history');list.replaceChildren();
  if(!reports.length){const p=document.createElement('p');p.className='muted';p.textContent='No saved reports yet.';list.append(p);}
  for(const row of reports){
    const button=document.createElement('button');button.type='button';button.textContent=String(row.input.question).slice(0,100)+' · '+new Date(row.createdAt).toLocaleString();
    button.addEventListener('click',()=>{selected=row;byId('detail-question').textContent=row.input.question;byId('detail-answer').replaceChildren(renderAnswer(row.output.content));byId('detail-receipt').textContent='Model: '+row.model+' · Report: '+row.id;byId('delete-confirm').hidden=true;byId('confirm-delete').hidden=true;if(dialog.showModal)dialog.showModal();else dialog.setAttribute('open','');});list.append(button);
  }
}
function close(){selected=null;if(dialog.close)dialog.close();else dialog.removeAttribute('open');}
function authenticated(active){byId('workspace').hidden=!active;byId('login-card').hidden=active;byId('logout').hidden=!active;}
byId('login').addEventListener('submit',async event=>{event.preventDefault();const submit=event.target.querySelector('button');submit.disabled=true;try{const body=await call('/api/auth/login',{method:'POST',body:JSON.stringify(Object.fromEntries(new FormData(event.target)))});token=body.token;sessionStorage.setItem('multiples-companion-token',token);authenticated(true);event.target.reset();status.textContent='Signed in.';await history();}catch(error){status.textContent=error.message;}finally{submit.disabled=false;}});
byId('fill-demo').addEventListener('click',async()=>{const button=byId('fill-demo');button.disabled=true;try{const {email,password}=await call('/api/auth/demo-credentials');const login=byId('login');login.elements.namedItem('email').value=email;login.elements.namedItem('password').value=password;status.textContent='Demo credentials filled. Select Sign in to continue.';}catch(error){status.textContent=error.message;}finally{button.disabled=false;}});
byId('logout').addEventListener('click',()=>{stop();version++;token='';sessionStorage.removeItem('multiples-companion-token');reports=[];current=null;close();authenticated(false);byId('history').replaceChildren();status.textContent='Signed out.';});
byId('coach-nav').addEventListener('click',()=>question.focus());
for(const button of form.querySelectorAll('[data-example]'))button.addEventListener('click',()=>{question.value=examples[Number(button.dataset.example)];status.textContent='Complete example loaded. Review the question, then generate.';});
byId('cancel-request').addEventListener('click',stop);window.addEventListener('pagehide',()=>{stop();version++;});
form.addEventListener('submit',async event=>{
  event.preventDefault();if(request||!form.reportValidity())return;const controller=new AbortController(),revision=++version;request=controller;lock(true);status.textContent='Preparing your coaching report…';
  try{const body=await call('/api/ai/exercise-coach',{method:'POST',signal:controller.signal,body:JSON.stringify({question:question.value})});if(controller.signal.aborted||revision!==version)return;show(body);status.textContent='Report received and saved.';await history();}
  catch(error){if(!controller.signal.aborted&&revision===version)status.textContent=error.message;}
  finally{if(request===controller){request=null;lock(false);}}
});
byId('copy-report').addEventListener('click',async()=>{try{await navigator.clipboard.writeText(readableAnswer(current.content||current.output.content));status.textContent='Report copied.';}catch{status.textContent='Copy is unavailable. Use Download.';}});
byId('download-report').addEventListener('click',()=>{const url=URL.createObjectURL(new Blob([readableAnswer(current.content||current.output.content)],{type:'text/plain;charset=utf-8'})),anchor=document.createElement('a');anchor.href=url;anchor.download='multiples-coaching-report.txt';anchor.click();URL.revokeObjectURL(url);});
byId('cancel-detail').addEventListener('click',close);dialog.addEventListener('close',()=>{selected=null;});
byId('edit-report').addEventListener('click',()=>{question.value=selected.input.question;close();question.focus();status.textContent='Question loaded for editing. Generate to create a new report.';});
byId('delete-report').addEventListener('click',()=>{byId('delete-confirm').hidden=false;byId('confirm-delete').hidden=false;});
byId('confirm-delete').addEventListener('click',async()=>{if(!selected)return;const id=selected.id,button=byId('confirm-delete');button.disabled=true;try{await call('/api/ai/history/'+id,{method:'DELETE'});close();status.textContent='Saved report deleted.';await history();}catch(error){status.textContent=error.message;}finally{button.disabled=false;}});
if(token)call('/api/auth/me').then(async()=>{authenticated(true);await history();}).catch(()=>{token='';sessionStorage.removeItem('multiples-companion-token');authenticated(false);});
