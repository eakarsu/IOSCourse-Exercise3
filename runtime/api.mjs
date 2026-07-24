import http from 'node:http';
import crypto from 'node:crypto';
import { literal, query } from './db.mjs';

const port=Number(process.env.BACKEND_PORT);
const json=(res,status,body)=>{res.writeHead(status,{'Content-Type':'application/json','Access-Control-Allow-Origin':`http://127.0.0.1:${process.env.FRONTEND_PORT}`,'Access-Control-Allow-Headers':'Authorization, Content-Type'});res.end(JSON.stringify(body));};
const readBody=req=>new Promise((resolve,reject)=>{let text='';req.on('data',chunk=>{text+=chunk;if(text.length>1_000_000)reject(new Error('request too large'));});req.on('end',()=>{try{resolve(text?JSON.parse(text):{});}catch(error){reject(error);}});req.on('error',reject);});
const sha=value=>crypto.createHash('sha256').update(value).digest('hex');
function verify(password,stored){const [kind,salt,digest]=String(stored).split('$');if(kind!=='scrypt'||!salt||!digest)return false;const candidate=crypto.scryptSync(password,salt,32);const expected=Buffer.from(digest,'hex');return candidate.length===expected.length&&crypto.timingSafeEqual(candidate,expected);}
function actor(req){const token=String(req.headers.authorization||'').replace(/^Bearer\s+/i,'');if(!token)return null;const row=query(`SELECT u.id,u.email,u.display_name,u.role FROM runtime_sessions s JOIN runtime_users u ON u.id=s.user_id WHERE s.token_hash=${literal(sha(token))} AND s.expires_at>NOW() AND u.active=TRUE LIMIT 1`,{rows:true});if(!row)return null;const [id,email,displayName,role]=row.split('\t');return{id,email,displayName,role};}

const server=http.createServer(async(req,res)=>{
  if(req.method==='OPTIONS'){res.writeHead(204,{'Access-Control-Allow-Origin':`http://127.0.0.1:${process.env.FRONTEND_PORT}`,'Access-Control-Allow-Headers':'Authorization, Content-Type','Access-Control-Allow-Methods':'GET,POST,OPTIONS'});return res.end();}
  const url=new URL(req.url||'/',`http://127.0.0.1:${port}`);
  try{
    if(req.method==='GET'&&url.pathname==='/api/health')return json(res,200,{status:'ok'});
    if(req.method==='POST'&&url.pathname==='/api/auth/login'){
      const body=await readBody(req);const email=String(body.email||'').trim().toLowerCase();const password=String(body.password||'');
      const row=query(`SELECT id,email,password_hash,display_name,role FROM runtime_users WHERE email=${literal(email)} AND active=TRUE LIMIT 1`,{rows:true});
      if(!row)return json(res,401,{error:'Invalid credentials'});
      const [id,userEmail,passwordHash,displayName,role]=row.split('\t');if(!verify(password,passwordHash))return json(res,401,{error:'Invalid credentials'});
      const token=crypto.randomBytes(32).toString('hex');query(`INSERT INTO runtime_sessions(token_hash,user_id,expires_at) VALUES(${literal(sha(token))},${literal(id)}::uuid,NOW()+INTERVAL '24 hours')`);
      return json(res,200,{token,user:{id,email:userEmail,name:displayName,role}});
    }
    if(req.method==='GET'&&url.pathname==='/api/auth/me'){const user=actor(req);return user?json(res,200,{user}):json(res,401,{error:'Authentication required'});}
    if(url.pathname.startsWith('/api/ai/')){
      const user=actor(req);if(!user)return json(res,401,{error:'Authentication required'});
      if(req.method==='GET'&&url.pathname==='/api/ai/history'){
        const rows=query(`SELECT json_build_object('id',id,'input',input,'output',output,'model',model,'createdAt',created_at)::text FROM runtime_ai_interactions WHERE user_id=${literal(user.id)}::uuid ORDER BY created_at DESC LIMIT 50`,{rows:true});
        return json(res,200,{history:rows?rows.split('\n').map(JSON.parse):[]});
      }
      if(req.method==='POST'&&url.pathname==='/api/ai/exercise-coach'){
        const body=await readBody(req);const question=String(body.question||'').trim();if(!question)return json(res,400,{error:'question is required'});
        const base=String(process.env.OPENROUTER_BASE_URL||'').replace(/\/+$/,'');const model=String(process.env.OPENROUTER_MODEL||'').trim();const key=String(process.env.OPENROUTER_API_KEY||'').trim();
        if(base!=='https://openrouter.ai/api/v1'||!model||!key)throw new Error('Exact OpenRouter configuration is required');
        const response=await fetch(`${base}/chat/completions`,{method:'POST',headers:{Authorization:`Bearer ${key}`,'Content-Type':'application/json','X-Title':'Multiples Exercise Coach'},body:JSON.stringify({model,messages:[{role:'system',content:'You are a concise math coach. Help learners reason about multiples with one clear worked example and one check-for-understanding question.'},{role:'user',content:question}],max_tokens:500})});
        if(!response.ok)throw new Error(`OpenRouter API error (${response.status})`);const provider=await response.json();const content=String(provider.choices?.[0]?.message?.content||'').trim();if(!content)throw new Error('OpenRouter returned an empty response');
        const saved=query(`INSERT INTO runtime_ai_interactions(user_id,input,output,model) VALUES(${literal(user.id)}::uuid,${literal(JSON.stringify({question}))}::jsonb,${literal(JSON.stringify({content}))}::jsonb,${literal(model)}) RETURNING id`,{rows:true});
        return json(res,200,{content,model,interactionId:Number(saved)});
      }
    }
    return json(res,404,{error:'Not found'});
  }catch(error){console.error(error.message);return json(res,500,{error:'Internal service error'});}
});
server.listen(port,'127.0.0.1',()=>console.log(`Multiples runtime API listening on ${port}`));
