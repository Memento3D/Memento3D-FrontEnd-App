import test from 'node:test';
import assert from 'node:assert/strict';
import { Group, Matrix4 } from 'three';
import { CustomizationLoads } from '../src/customization_runtime.js';

const matrix = new Matrix4().makeTranslation(1, 2, 3).toArray();
const asset = id => ({assetVersionId:id,sha256:id,url:id,matrixColumnMajor:matrix});
const scene = {modelOutputId:'output',fitResultId:'fit',baseModel:{url:'base',sha256:'base'},assets:[asset('cap'),asset('hair'),asset('glasses')],groups:[
  {id:'headwear',required:true,noneAllowed:false,assetVersionIds:['cap','hair']},
  {id:'glasses',required:false,noneAllowed:true,assetVersionIds:['glasses']},
]};
const command = (requestId, headwear='cap', glasses=null) => ({requestId,scene,selection:{headwear,glasses}});
const result = () => { const root=new Group();return {scene:root,scenes:[root]}; };

test('loads selected assets once, applies placement once, keeps root/camera across swaps', async()=>{
  const fetched=[],shown=[],events=[];
  const runtime=new CustomizationLoads({load:async url=>{fetched.push(url);return result();},show:(root,first)=>shown.push({root:root.scene,first}),emit:e=>events.push(e),clear:()=>{}});
  await runtime.receive(command('1'));
  assert.deepEqual(fetched,['base','cap']);
  const root=runtime.root;
  assert.deepEqual(root.children[1].children[0].matrix.toArray(),matrix);
  await runtime.receive(command('2','hair','glasses'));
  await runtime.receive(command('3'));
  assert.equal(runtime.root,root);
  assert.deepEqual(shown.map(v=>v.first),[true,false,false]);
  assert.deepEqual(fetched,['base','cap','hair','glasses']);
  assert.equal(root.children[1].children.length,1);
  assert.deepEqual(events.map(e=>e.requestId),['1','2','3']);
  runtime.dispose();
});

test('failed accessory preserves visible selection and retries without downloading base',async()=>{
  let fail=true,baseCount=0;
  const events=[];
  const runtime=new CustomizationLoads({load:async url=>{if(url==='base')baseCount++;if(url==='hair'&&fail)throw Error('offline');return result();},show:()=>{},emit:e=>events.push(e),clear:()=>{}});
  await runtime.receive(command('1'));
  const previous=runtime.slots.children[0];
  await runtime.receive(command('2','hair'));
  assert.equal(runtime.slots.children[0],previous);
  assert.equal(events.at(-1).type,'loadError');
  fail=false;
  await runtime.receive(command('3','hair'));
  assert.equal(baseCount,1);
  assert.equal(runtime.loaded,true);
  runtime.dispose();
});

test('slow old selection cannot replace latest choice',async()=>{
  let release;
  const pending=new Promise(resolve=>{release=()=>resolve(result());});
  const events=[];
  const runtime=new CustomizationLoads({load:async url=>url==='hair'?pending:result(),show:()=>{},emit:e=>events.push(e),clear:()=>{}});
  await runtime.receive(command('1'));
  const slow=runtime.receive(command('2','hair'));
  await runtime.receive(command('3','cap','glasses'));
  release();await slow;
  assert.equal(events.at(-1).requestId,'3');
  assert.equal(runtime.slots.children.length,2);
  runtime.dispose();
});

test('rejects unsupported asset without loading any file',async()=>{
  let loads=0;const events=[];
  const runtime=new CustomizationLoads({load:async()=>{loads++;return result();},show:()=>{},emit:e=>events.push(e),clear:()=>{}});
  await runtime.receive(command('1','unknown'));
  assert.equal(loads,0);assert.equal(events[0].code,'invalidCommand');runtime.dispose();
});
