import { Group, Matrix4 } from 'three';
import { disposeScenes } from './model_runtime.js';

/** Per-output cache. An accessory swap changes children, never the base root/camera. */
export class CustomizationLoads {
  constructor({load, show, emit, clear}) {
    Object.assign(this,{load,show,emit,clear});
    this.cache=new Map();this.owned=new Set();this.generation=0;this.loaded=false;this.disposed=false;this.root=null;this.identity=null;
    this.epoch=0;
  }
  async model(asset,id) {
    const key=`${id}:${asset.sha256}`;
    if(this.cache.has(key))return this.cache.get(key);
    const epoch=this.epoch;
    const promise=this.load(asset.url,()=>{}).then(result=>{
      if(this.disposed||epoch!==this.epoch){disposeScenes(result.scenes);throw Error('disposed');}
      this.owned.add(result.scene);return result.scene;
    });
    this.cache.set(key,promise);promise.catch(()=>{if(this.cache.get(key)===promise)this.cache.delete(key);});return promise;
  }
  async receive(command) {
    if(this.disposed||!command||typeof command.requestId!=='string')return;
    const ticket=++this.generation;this.active=command.requestId;this.loaded=false;
    try {
      const {scene,selection}=command;
      if(!scene?.modelOutputId||!scene.fitResultId||!scene.baseModel?.sha256||!Array.isArray(scene.assets)||!Array.isArray(scene.groups)||!selection)throw Error('invalidCommand');
      const identity=`${scene.modelOutputId}:${scene.fitResultId}:${scene.baseModel.sha256}`;
      if(this.identity&&this.identity!==identity){this.reset();this.active=command.requestId;}
      this.identity=identity;
      const chosen=scene.groups.flatMap(group=>{
        const id=selection[group.id];
        if(id===null&&group.noneAllowed&&!group.required)return [];
        if(!group.assetVersionIds.includes(id))throw Error('invalidCommand');
        const asset=scene.assets.find(value=>value.assetVersionId===id);
        if(!asset||asset.matrixColumnMajor?.length!==16||!asset.matrixColumnMajor.every(Number.isFinite))throw Error('invalidCommand');
        return [asset];
      });
      const [base,...assets]=await Promise.all([this.model(scene.baseModel,'base'),...chosen.map(asset=>this.model(asset,asset.assetVersionId))]);
      if(this.disposed||ticket!==this.generation)return;
      const first=!this.root;
      if(first){this.root=new Group();this.slots=new Group();this.root.add(base,this.slots);}
      this.slots.clear();
      assets.forEach((object,index)=>{
        const placement=new Group();placement.matrixAutoUpdate=false;
        placement.matrix.copy(new Matrix4().fromArray(chosen[index].matrixColumnMajor));placement.add(object);this.slots.add(placement);
      });
      this.show({scene:this.root,scenes:[this.root]},first);this.loaded=true;
      this.emit({type:'modelLoaded',requestId:this.active});
    }catch(error){if(!this.disposed&&ticket===this.generation)this.emit({type:'loadError',requestId:this.active,code:error.message==='invalidCommand'?'invalidCommand':'resourceLoadFailed'});}
  }
  reset(){this.epoch++;this.clear();this.root?.removeFromParent();disposeScenes(this.owned);this.owned.clear();this.cache.clear();this.root=null;this.identity=null;this.loaded=false;}
  dispose(){this.disposed=true;this.generation++;this.reset();}
}
