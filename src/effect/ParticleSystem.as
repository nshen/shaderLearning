package effect
{
	
	import flash.display3D.Context3D;
	import flash.geom.Matrix3D;

	public class ParticleSystem
	{
		protected var _particles : Vector.<Particle>;		// 粒子
		protected var _emitter : ParticleEmitterBase;		// 发射器
		
		public function ParticleSystem(maxCapacity:uint , emitter:ParticleEmitterBase)
		{
			
			_maxCapacity = maxCapacity ;
			
			_particles = new Vector.<Particle>(_maxCapacity, true);
			
			_emitter = emitter;
			_emitter.particleSystem = this;
			
			//			_displayer = displayer;
			
			_material = new ParticleSystemMaterial(this);
		}
		
		
		//		protected var _displayer:nParticleDisplayer;        // 显示器
		protected var _material:ParticleSystemMaterial;
		protected var _maxCapacity:uint = 0 ;           //最多粒子数
		protected var _lastIndex:int = -1;		// 上次创建的粒子的index
		protected var _maxLiveIndex:int = -1;				// 存活粒子最大index
		protected var _emitting:Boolean = false;
		
		
		public function get particles():Vector.<Particle>
		{
			return _particles;
		}
		
		public function get maxLiveIndex():int
		{
			return _maxLiveIndex;
		}
		
		public function get maxCapacity():uint
		{
			return _maxCapacity;
		}
		
		public function set emitter(value : ParticleEmitterBase) : void {_emitter = value;}
		public function get emitter() : ParticleEmitterBase {return _emitter;}
		
		//由Emitter调用，生产一个particle 交给emitter初始化
		public function generateParticle():Particle
		{
			if( ++_lastIndex >= _maxCapacity )
				_lastIndex = 0 ; 
//			trace("----------")
//			trace(_maxLiveIndex,_maxCapacity );
			if(_maxLiveIndex < _maxCapacity -1 )
			{
				_maxLiveIndex ++ ;
//			trace(_maxLiveIndex,_maxCapacity );
//			trace("----------")
			}
			if(_particles[_lastIndex])
			{
				_particles[_lastIndex].reset();
			}else
			{
				_particles[_lastIndex] = new Particle(_lastIndex);
				_material.uploadParticle(_particles[_lastIndex],true);
			}
			return _particles[_lastIndex];
		}
		
		public function stop(immediately : Boolean) : void
		{
			_emitting = false;
			if(immediately)
			{	
				for(var i:int = 0 ; i<= _maxLiveIndex ; i++)
				{
					_particles[i].die();
				}
			}
		}
		
		public function start() : void 
		{
			_emitting = true;
		}
		
		
		//emitter初始化后，会交到这里上传粒子
		public function uploadParticle(newParticle:Particle):void
		{
			_material.uploadParticle(newParticle,false);
		}
		
		public function step(elapsed:int):void 
		{
//			trace(_maxLiveIndex , _particles.length)
			for(var i:int = 0 ; i<= _maxLiveIndex ; i++)
			{
				if(!_particles[i].isDead())
				{
//					nowMaxLiveIndex = i;
					_particles[i].update(elapsed);
				}
			}
//			if(nowMaxLiveIndex < _maxLiveIndex)
//				_maxLiveIndex = nowMaxLiveIndex;
			
			
			if(_emitter && _emitting)
				_emitter.update(elapsed);
			
		}
		
		
		public function handleDeviceLoss():void 
		{
			super.handleDeviceLoss();
			_material.handleDeviceLoss();
		}
		
		public function draw(context:Context3D,mvp:Matrix3D):void
		{
			_material.mvp = mvp;
			_material.render(context);
//			_material.blendMode = blendMode;
//			_material.modelMatrix = worldModelMatrix;
//			_material.viewProjectionMatrix = camera.getViewProjectionMatrix(false);
//			
//			_material.maxCapacity = _maxCapacity;
//			//			_material.currentTime = currentTime;
//			_material.render(context, null, 0,(_maxLiveIndex+1) * 2); //dont use facelist
		}
		
		public function dispose():void 
		{
			if(_material)
			{
				_material.dispose();
				_material = null;
			}
			super.dispose();
		}
	}
}